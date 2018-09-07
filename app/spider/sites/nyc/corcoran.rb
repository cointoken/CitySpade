module Spider
  module NYC
    class Corcoran < Spider::NYC::Base
      def domain_name
        'http://www.corcoran.com'
      end
      def base_url(flag = 'sales')
        domain_name + "/nyc/Search/Listings?SaleType=#{flag}&SortBySimplified=DateListed&Page="
      end
      private :domain_name, :base_url

      def page_urls(flag)
        # max_id = flag == 'Sale' ? 10 : 10
        max_id = 30
        (0..max_id).map do |i|
          url = URI.escape(base_url(flag) + i.to_s)
          url
        end
      end

      def listings(options={})
        %W(Rent Sale).each do |flag|
          @logger.info :sale, 'begin http get sale type'
          options.merge! :flag => flag
          page_urls(flag).each do |url|
            @logger.info 'get url', url
            res = get(url)
            if res.code == '200'
              Nokogiri::HTML(res.body).css('table.listings-table tbody tr').each do |doc|
                listing = retrieve_listing(doc, url, options)
                @logger.info listing
                check_title listing
                listing[:city_name] ||= @city_name
                listing[:state_name] ||= @state_name
                if block_given?
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
        listing[:flag]  = get_flag_id(options[:flag])  if options[:flag].present?
        link   = doc.css('td.address')[0].css('a')
        listing[:title] = link.first.text.strip
        listing[:neighborhood_name] = link.css('a.hood').text.strip
        listing[:unit]  = doc.css('td.unit').first.text.strip
        listing[:beds]  = doc.css('td.beds').first.text.strip
        listing[:baths] = doc.css('td.baths').first.text.strip
        listing[:sq_ft] = doc.css('td.sqft').first.text.strip if doc.css('td.sqft').first.text.present?
        price  = doc.css('td.price').first.text.strip
        listing[:price] = price.gsub(/\$|\,/,'') if price.present?
        listing[:listing_type] = doc.css('td.rooms').first.text.strip
        return {} unless doc.css('td.contact').first.present? && doc.css('td.contact').first.css('.agent-name').first.present?
        listing[:contact_name] = doc.css('td.contact').first.css('.agent-name').first.text.strip
        listing[:contact_tel]  = doc.css('td.contact').first.css('.agent-contact').first.text.split('|')[0].strip.gsub(/\D/, '')
        href   = link.first['href']
        href   = domain_name + href if href !~ /^http/
        listing[:url]  = href
        listing[:flag] = get_flag_id(options[:flag])  if options[:flag].present?
        # get image in listing details
        # listing[:images] = retrieve_images(doc, listing, url) if options[:image]
        res = get(listing[:url])
        if res.code == '200'
          doc_d = Nokogiri::HTML(res.body)
          get_detail(doc_d, listing)
        end
        listing
      end

      def get_detail(doc, listing)
        desc = doc.css('.Listing-Description').first
        listing[:description] = desc.text.strip if desc.present?
        amens = doc.css('#key-features ul li').map{|t| t.text.strip}.delete_if{|t| t.blank?}
        if amens.present?
          listing[:amenities] = amens
        end
        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_images(doc, listing)
      end

      def retrieve_agents doc, listing
        agents = []
        agent_infos = doc.css(".agent-card.AgentCard")
        agent_infos.each do |agent_info|
          agent = {}
          agent[:name] = agent_info.css(".info a.name").text if agent_info.css(".info a.name").text.present?
          agent[:tel] = agent_info.css(".info span.contact").first.text.gsub(/\D/, '') if agent_info.css(".info span.contact").first.present?
          agent[:origin_url] = agent_info.css("img").first.attributes["src"].value if agent_info.css("img").first.present?
          agent[:website] = abs_url agent_info.css("a").first.attributes["href"].value + "?tIndividualOnly=True" if agent_info.css('a').first.present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={} }
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  "Corcoran",
          website: domain_name,
          tel: "2123553550",
          email: "info@corcoran.com",
          street_address: "660 Madison Ave New York",
          zipcode: "10065",
          introduction: %q{Real Estate Agents affiliated with The Corcoran Group are independent contractor sales associates and are not employees of The Corcoran Group.}
        }
      end

      def retrieve_images(doc, listing)
        listing[:images] = []
        imgdocs = doc.css('.Thumbnails-Holder img')
        imgdocs.each do |img|
          src = img['src']
          if src =~ /\/box\/.+/
            src.sub!(/\/box\/.+/, '')
          elsif src =~ /default/i
            next
          end
          matchtext = /mediarouting/.match(src)
          src = "http://" + matchtext.to_s + matchtext.post_match 
          listing[:images] << {origin_url: src }
        end
        listing
      end

      def get_title(doc, listing = {})
        tl = doc.css("#address-info .primary-font").first
        if tl
          listing[:title] = tl.text.strip
        end
      end
    end
  end
end
