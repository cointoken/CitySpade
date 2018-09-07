module Spider
  module NYC
    class Bhsusa < Spider::NYC::Base
      def initialize
        super
        @listing_agent_css = ".listing-agent-info a"
      end

      def domain_name
        'http://www.bhsusa.com'
      end
      def base_url(flag = 'sale')
        domain_name + "/for-#{flag}/new-york-city/results/just-listed/sorted-by-date/page-"
      end
      private :domain_name, :base_url

      def page_urls(flag)
        (1..20).map do |i|
          url = URI.escape(base_url(flag) + i.to_s)
          url
        end
      end

      def listings(options={})
        %W(rent sale).each do |flag|
          @logger.info :sale, 'begin http get sale type'
          options.merge! :flag => flag
          page_urls(flag).each do |url|
            @logger.info 'get url', url
            res = get(url)
            if res.code == '200'
              Nokogiri::HTML(res.body).css('div.content div.property-result').each do |doc|
                listing = retrieve_listing(doc, url, options)
                next unless listing

                check_title listing
                if block_given?
                  @logger.info listing
                  yield(listing)
                else
                  listing
                end
              end
            else
              []
            end
          end
        end
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        phtml = doc.css('p').first
        link   = phtml.css('a').first
        titles = link.text.split(' ')
        pstr = phtml.text.strip
        listing[:listing_type] = titles.last.downcase.camelize
        listing[:title] = titles[0..-2].join(' ')
        return false unless is_full_address?(listing[:title])
        listing[:flag] = get_flag_id(options[:flag])  if options[:flag].present?
        listing[:beds]  = (pstr.match(/Bedrooms: (\d+)/) || [0,0]) [1]
        listing[:baths] = (pstr.match(/Bathrooms: (\d+\.\d+)/) || [0,0])[1]
        listing[:price] = (pstr.match(/\$\d+(\,\d{3})+/)||['0'])[0].gsub(/\$|\,/,'')
        listing[:contact_name] = phtml.css('a').last.text.strip
        listing[:contact_tel]  = pstr.match(/(\(\d+\)\s?)?(\d+\-)?\d+$/)[0].gsub(/\D/, '')
        if phtml.css('.contract-signed').first.present? && phtml.css('.contract-signed').first.text.present?
          listing[:status] = 1
        end
        href   = link['href']
        href   = domain_name + href if href !~ /^http/
        listing[:url]  = href
        listing[:neighborhood_name] = get_neighborhood_name_for_url(href)
        # get image in detail page
        # listing[:images] = retrieve_images(doc, listing, url) if options[:image]
        res = get(listing[:url])
        if res.code == '200'
          doc_d = Nokogiri::HTML(res.body)
          get_detail(doc_d, listing)
        end
        listing
      end

      def get_detail(doc, listing)
        desc = doc.css(".details-left p.notes")
        if desc
          listing[:description] = desc.text.strip
        end
        amen = doc.css('.details-right p').last
        if amen
          amen = amen.children.map{|a| a.text.gsub(':', '').strip}.delete_if{|t| t.blank?}
          len = amen.size / 2
          amens = []
          (0...len).each do |l|
            if amen[l*2 + 1].downcase == 'yes'
              amens << amen[l * 2]
            end
          end
          listing[:amenities] = amens
        end

        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_images(doc, listing)
      end

      def retrieve_agents(doc, listing)
        # get all the agents
        agents = []
        doc.css(".listing-agent").each do |listing_agent|
          agent = {}
          agent_url = get_agent_url(listing_agent)
          agent_info = listing_agent.css(".listing-agent-info")
          agent[:name] = agent_info.css("a strong").text.strip
          agent_info.css("a").each do |info|
            agent[:email] = info.text.strip.gsub(/mailto\:/, "") if info.text.match(/@/)
          end
          listing_agent.css(".listing-agent-info").text.split(" ").each do |txt|
            agent[:tel] = txt.gsub(/\D+/, "") if txt.match(/[\d\-]+/)
          end
          agent[:website] = agent_url
          agent[:origin_url] = abs_url listing_agent.css("a img").attr("src").value if listing_agent.css("a img").present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        # get broker
        listing[:broker] = {
          name: "Brown Harris Stevens Residential Sales, LLC",
          tel: "18882477356",
          email: "smalpelli@bhsusa.com",
          website: domain_name,
          introduction: "All information is from sources deemed reliable but is subject to errors, omissions, changes in price, prior sale or withdrawal without notice. No representation is made as to the accuracy of any description. All measurements and square footages are approximate and all information should be confirmed by customer. All rights to content, photographs and graphics reserved to Broker. Customer should consult with its counsel regarding all closing costs, including without limitation the New York State 1% tax paid by buyers on residential properties over $1 million. Broker represents the seller/owner on Broker's own exclusives, except if another agent of Broker represents the buyer/tenant, in which case Broker will be a dual agent with designated agents representing seller/owner and buyer/tenant. Broker represents the buyer/tenant when showing the exclusives of other real estate firms. Broker actively supports equal housing opportunities"
        }
      end

      def retrieve_images(doc, listing)
        imgdocs = doc.css('#slides img')
        listing[:images] = []
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['src'].sub(/\_(s|r)\./, '_l.'))} unless imgdoc['src'].match 'no-property'
        end
        listing
      end

      def get_neighborhood_name_for_url(href)
        url = href.sub(/#{domain_name}\//, '')
        url.split('/').first || url.split('/').first
      end

      def get_title doc, listing = {}
        tl = doc.css('.section-left').first
        if tl
          listing[:title] = tl.text.split(' - $').first
        end
      end
    end
  end
end
