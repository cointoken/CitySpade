module Spider
  module NYC
    class Townrealestate < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "a.listingAnchor"
        @listing_image_css  = "#photoContainer img"
        @listing_callbacks[:image] = ->(img){
          if img['src'].downcase.include?('listing')
            abs_url(img['src'])
          end
        }
        @get_custom_html = ->(url) { RestClient.get url }
        @listing_agent_css = ".agent_pic a"
      end

      def domain_name
        'http://www.townrealestate.com/'
      end

      def page_urls(opts)
        param_opts = {sale: {
          priceFrom:100000,
          priceTo:1000000000,
          bedFrom:0,
          bedTo:100,
          bathFrom:1,
          bathTo:100,
          'submit_search.x' => 60,
          'submit_search.y' => 10,
          submit_search:'Search',
          oh:'',
          listing_type:'S',
        }}
        param_opts[:rent] = param_opts[:sale].clone
        param_opts[:rent][:listing_type] = 'R'
        param_opts[:rent][:priceFrom] = 1000
        param_opts[:rent][:priceTo]   = 100000
        param_opts[:rent]['submit_search.x'] = 50
        param_opts[:rent]['submit_search.y'] = 7
        post_url = abs_url('/search.html')
        opts[:flags] ||= %w{rent sale}
        urls = []
        res = get(post_url)
        doc = Nokogiri::HTML(res.body)
        loc_ids = doc.css('input[name="loc[]"]').map{|s| s['value']}
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)
          loc_ids.each do |loc|
            url = ->{
              post post_url, param_opts[flag.to_sym].merge("loc[]" => loc)
            }
            urls << [url, nil]
            60.times do |t|
              if t > 0
                url = abs_url("/search_results.html?position=#{t * 15}&orderby=")
              else
                url = abs_url("/search_results.html")
              end
              urls << [url, flag_i]
            end
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        listing[:title] = doc.css('.listing-title-big').text.strip.split(',').first
        if listing[:title] !~ /\d+\s/
          listing[:is_full_address] = false
        else
          listing[:is_full_address] = true
        end
        raw_neighborhood = doc.css('.listing_head').children[3]
        if raw_neighborhood && raw_neighborhood.text.include?('NEIGHBORHOOD:')
          listing[:raw_neighborhood] = raw_neighborhood.text.remove('NEIGHBORHOOD:').strip
        end
        detail = doc.css('div.listing_details')
        detail_text = detail.text
        if detail_text =~ /\sRENTED\s/i
          listing[:status] = 1
        end
        hash = {}
        hash[:listing_type] = detail_text.match(/Type:\s(\w+)\s/)
        hash[:price]        = detail_text.match(/Price:\s(\$\d+.+)\s/)
        hash[:beds]         = detail_text.match(/Bedrooms:\s(\d+)/)
        hash[:baths]        = detail_text.match(/Baths:\s(\d(\.5)?)/)
        hash[:sq_ft]        = detail_text.match(/SqFt:\s+((\d|\,)+)/)
        hash.each do |key, value|
          if value
            if [:price, :sq_ft].include? key
              val = value[1].gsub(/\D/, '')
            else
              val = value[1]
            end
            listing[key] = val
          end
        end
        listing[:contact_name] = doc.css('div.agent_content a.agent_name').text.strip
        listing[:contact_tel]  = doc.css('div.agent_content span[itemprop="telephone"]').first.try(:text).try :gsub, /\D/, ''
        amenities = detail.css('.bu_amenities')
        listing[:amenities] = []
        amenities.each do |amens|
          amens.children[1..-1].each do |amen|
            if amen.text.strip.present?
              listing[:amenities] << amen.text.strip.split('|').map{|str| restrip_str(str)}
            end
          end
        end
        listing[:amenities] = listing[:amenities].flatten.uniq.map(&:strip)
        listing[:description] = detail.css('.listing_descr').text.strip
        script = doc.css('body script').last#.text
        if script
          script = script.text
          listing[:lng] = (script.match(/lon\s?\=\s?(.+)\;/)||[])[1]
          listing[:lat] = (script.match(/lat\s?\=\s?(.+)\;/)||[])[1]
        end
        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_open_house(doc, listing) if doc.css(".openhouse").present?
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(".agent_wrapper .agent_body").each do |listing_agent|
          agent = {}
          agent_url = get_agent_url(listing_agent)
          agent[:name] = listing_agent.css(".agent_content .agent_name").text.try(:strip)
          agent[:email] = listing_agent.css(".agent_email").text.try(:strip)
          listing_agent.css(".agent_content div span").each do |info|
            agent[:tel] = info.text.gsub(/\D/, "") if info.text.match(/([\d\(\)\-]+)/)
          end
          agent[:origin_url] = listing_agent.css(".agent_pic a img").attr("src").value if listing_agent.css(".agent_pic a img").present?
          agent[:website] = agent_url
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  "Town Residential",
          tel: "2123989800",
          email: "legaldepartment@townrealestate.com",
          street_address: "25 West 39th Street",
          zipcode: "10018",
          website: domain_name,
          introduction: %q{Town's approach is all-encompassing yet remarkably simple. We dedicate equal value and resources to sales, new development marketing and rentals, striving to be a leader in all three. We recognize that the common thread in each and every real estate transaction is a client with similar needs: exceptional customer service, transparency of information, neighborhood expertise and professional guidance through the process. Town embraces these needs and works diligently to cater to them on every level of our business.

Founded in 2010 by a dynamic executive team, Town strives to become an integral part of the New York real estate landscape. Its founding members are a close-knit group of leaders with acclaimed success and expertise in luxury sales, new development marketing and rentals. Innovative, experienced and built on strong business principles, Town is perfectly poised to deliver dramatic results in today's real estate market.}
        }
      end

      def retrieve_open_house doc, listing
        listing[:open_houses] = []
        doc.css(".openhouse").each do|openhouse|
          arr = openhouse.children[0].text.strip.split(/\s/)
          begin_end_time = arr.pop
          begin_time = begin_end_time.split("-")[0]
          end_time = begin_end_time.split("-")[1]
          open_date = arr.join(" ").split(",").last.strip
          open_houses = {open_date: Date.parse(open_date), begin_time: Time.parse(begin_time), end_time: Time.parse(end_time)}
          listing[:open_houses] << open_houses
        end
        listing[:open_houses]
      end

      def restrip_str(str)
        str.gsub(/\s|\\t|\\n/, '')
      end

      def get_title doc, listing={}
        listing[:title] = doc.css('.listing-title-big').text.strip.split(',').first
      end
    end
  end
end
