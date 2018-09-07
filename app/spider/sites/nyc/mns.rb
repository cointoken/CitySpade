module Spider
  module NYC
    class Mns < Spider::NYC::Base

      def initialize(opts={})
        super
        @opts[:accept_cookie] ||= true
        @listing_agent_css = ".info a.name"
      end

      def domain_name
        'http://www.mns.com'
      end
      def page_url(opt={})
        "http://www.mns.com/nyc/#{opt[:flag]}/page:#{opt[:page]}"
      end

      def login
        opts = {
          login: 'KORHEQUE@GMAIL.COM',
          pass: 'KORHEQUE@ny'
        }
        login_url = domain_name + '/action/login/'
        post login_url, opts
      end
      private :domain_name

      def listings(options={})
        login
        options[:flags] = %w(sales rentals)
        options[:flags].each do |flag|
          @logger.info flag, 'begin http get sale type'
          if flag == 'sales'
            options[:pages] = 5
          else
            options[:pages] = 50
          end
          options.merge! :flag => flag
          (1..options[:pages]).each do |page|
            url = page_url(flag: flag, page: page)
            @logger.info 'get url', url
            res = get(url)
            if res.code == '200'
              docs = Nokogiri::HTML(res.body).css('ul.listing-list li a.address')
              if docs.present?
                docs.each do |doc|
                  href = abs_url doc['href']
                  next if href =~ /e\_\d+$/
                  listing_res = get(href)
                  if listing_res.code == '200'
                    html = Nokogiri::HTML(listing_res.body)
                    listing = retrieve_listing(html, href, options)
                    next unless listing
                    p listing
                    check_title listing
                    listing[:city_name] ||= @city_name
                    listing[:state_name] ||= @state_name
                    if block_given?
                      yield listing
                    else
                      listing
                    end
                  end
                end
              else
                break
              end
            end
          end
        end
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        title = doc.css('.coordinates-box span').first.children.first.text.strip
        if title =~ /\d/
          listing[:title] = title
        else
          listing[:neighborhood_name] = title
          listing[:is_full_address]      = false
        end
        return false unless get_title(doc, listing)
        dds = doc.css('.information-box dd').children.map{|a| a.text.strip}
        listing[:price] = dds.select{|a| a =~ /^\$/}.first.gsub(/\$|\,/, '')
        p listing, url
        listing[:beds]  = dds.select{|a| a =~ /bedroom/i}.first.try :gsub, /\D/, ''
        listing[:baths] = dds.select{|a| a =~ /bathroom/i}.first.try :gsub, /[a-z]/i, ''
        listing[:sq_ft] = dds.select{|a| a =~ /sq\./}.first.try :gsub, /\D/, ''
        listing[:no_fee] = true if dds.to_s =~ /no\s+fee/i
        listing[:url]   = url
        listing[:flag]  = get_flag_id(options[:flag])
        listing[:description] = doc.css('.listing-article .text').text.strip
        agent = doc.css('.agent_li').first
        if agent
          listing[:contact_name] = agent.css('a.name').text.strip
          listing[:contact_tel]  = agent.css('span').first.text.gsub(/\D/, '')
        end

        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_images(doc, listing)
        if amen = doc.css(".information-box ul").last
          if amen.present?
            amens = amen.css('li').map{|t| t.text.split(',').map(&:strip)}.flatten
            listing[:amenities] = amens if amens.present?
          end
        end
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(".agents-list .agent_li").each do |listing_agent|
          agent = {}
          agent[:name] = listing_agent.css(".info a.name").text.strip
          agent[:tel] = listing_agent.css(".info span").text.gsub(/\D+/, "") if listing_agent.css(".info span").text.present?
          agent[:email] = listing_agent.css(".info a.email-link").attr("href").value.gsub(/mailto\:/, "") if listing_agent.css(".info a.email-link").attr("href").present?
          agent[:website] = get_agent_url(listing_agent)
          agent[:origin_url] = listing_agent.css(".photo-box img").first.attr("src") if listing_agent.css(".photo-box img").first.present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  "MNS Real Impact Real Estate",
          tel: "2124759000",
          website: domain_name,
          introduction: %q{MNS is an innovative real estate brokerage specializing in the marketing, sale and rental of residential properties. The firm is the product of the two formerly successful companies, The Real Estate Group, which focused on resales and rentals, and The Developers Group, a new development marketing and sales company.

To increase impact, we seamlessly integrate marketing, sales, and technology to produce the most efficient sales possible at the highest market-driven prices. Our services reflect our unique position as trendsetters, innovators, and shapers of the market.

We focus on relationships rather than transactions, offering clients and customers an unsurpassed level of personalized service.

Our clients value our constant communication regarding their properties. We create a customized, strategic roadmap for the sale of each client's property. Through the use proprietary systems that track showings, advertising response, and website views, we ensure that our clients properties have heightened visibility, which leads to shorter selling times and higher selling prices. Developers and landlords treasure our wealth of knowledge gained through the successful sell out of many projects.

Our customers appreciate how we simplify the home buying process by providing relevant data and a framework for decision-making that makes the process fun, effective, and virtually stress free.

Our culture is open and collaborative, and our agents are creative and growth-oriented. Training and development are hallmarks of the firm.

Unrivaled strategy. Incomparable expertise.}
        }
      end

      def retrieve_images(doc, listing)
        listing[:images] = []
        imgdocs = doc.css('.slidelist .img-box img')
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['src'])} unless imgdoc['src'] =~ /default/i
        end
        listing
      end

      def get_title(doc, listing)
        script = doc.css("#wrapper script").first.text
        math = script.match(/address\:\s?+\"(.+)\"/)
        if math
          #listing[:formatted_address] = math[1]
          addrs = math[1].split(',')
          listing[:title] = addrs.first.strip
          listing[:raw_neighborhood] ||= addrs[1].strip
          return true
        else
          lat = script.match(/latitude\:\s?+(.+)\,/)
          lng = script.match(/longitude\:\s?+(.+)\,/)
          if lat && lng
            listing[:lat] = lat[1]
            listing[:lng] = lng[1]
            return true
          end
        end
        return false
      end

      def get_neighborhood_name_for_url(url)
        url = url.sub( domain_name + '/', '')
        urls = url.split('/')
        if urls.size == 5
          urls[2].gsub('-', ' ')
        else
          nil
        end
      end
    end
  end
end
