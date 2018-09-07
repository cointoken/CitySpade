module Spider
  module NYC
    class Halstead < Spider::NYC::Base
      def initialize(opts={})
        super
        @listing_agent_css = "a.agent-profile-photo"
      end

      def domain_name
        'http://www.halstead.com'
      end

      def flag_type_url(flag)
        if flag.starts_with?('rent')
          domain_name + '/rentals/new-york/properties/50-per-page'
        else
          domain_name + '/sales/new-york/properties/50-per-page'
        end
      end

      def pages_urls(flag, pages)
        (1..pages).map{|page|
          flag_type_url(flag) + "/page-#{page}"
        }
      end

      def listings(opts = {})
        # Listing.where('origin_url like ?', '%halstead.com%').update_all(status: 1)
        opts[:flags] ||= %W(rent sale)
        opts[:flags].each do |flag|
          @logger.info flag, "begin http get #{flag} for #{self.class}"
          opts.merge! :flag => flag
          #opts[:neighbors].each do |n|
          pages_urls(flag, opts[:page] || 20).each do |url|
            @logger.info "get #{url}"
            res = get(url)
            if res.code == '200'
              Nokogiri::HTML(res.body).css('.property-result').each do |doc|
                listing = retrieve_listing(doc, url, opts)
                next unless listing
                next unless listing[:title] =~ /^\d/
                check_title(listing)
                listing[:city_name] ||= @city_name
                listing[:state_name] ||= @state_name
                # listing[:neighborhood_name] ||= n
                listing[:status] ||= 0
                if block_given?
                  @logger.info listing
                  yield(listing)
                else
                  p listing
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
        agent = doc.css('.result-contact')
        if agent
          tel = agent.css('span').first
          if tel && tel = tel.text.gsub(/\D/, '')
            if tel =~ /^\d+$/
              listing[:contact_tel] = tel
            else
              return false
            end
          end
        end
        ameni = doc.css('.result-amenities p')
        if ameni && ameni = ameni.css('p').first
          ameni = ameni.children.map{|t| t.text}.delete_if{|s| s.blank?}
          if ameni.present?
            listing[:amenities] = ameni
          end
        end
        title = doc.css('.property-info a').first
        titles = title.text.split(',')
        if titles.size > 1
          listing[:neighborhood_name] = titles[1].strip
        end
        listing[:title] = titles.first
        listing[:url]   = abs_url(title['href'])
        price = doc.css('.property-info a')[1].text.strip
        if price =~ /\$/
          listing[:price] = price.gsub(/\D/, '')
        end
        infos = doc.css('.result-information p').text.strip
        infos = infos.gsub(/(Rental)|(beds)|baths.+|\s/i, '').split('/')
        if infos.size == 2
          listing[:beds] = infos.first.gsub(/\D/, '')
          listing[:baths] = infos.last
        end
        listing[:flag]  = get_flag_id(options[:flag])
        if listing[:url]
          res = get(listing[:url])
          if res.code == '200'
            doc_d = Nokogiri::HTML(res.body)
            get_detail(doc_d, listing)
          end
        end
        listing
      end

      def get_detail(d_doc, listing)
        amens = d_doc.css('.features strong').map{|t| t.text}.delete_if{|t| t.blank?}
        if listing[:neighborhood_name].blank?
          listing[:neighborhood_name] = d_doc.css('.details-header .location').text.split(',').first.try(:strip)
        end
        if amens.present?
          listing[:amenities] ||= []
          listing[:amenities] += amens
          listing[:amenities].uniq!
        end
        listing[:description] = d_doc.css('#notes .notes').text
        contact_name = d_doc.css('.listing-agent .agent-bold').first
        if contact_name
          listing[:contact_name] = contact_name.text.strip
        end

        if listing[:beds].blank? || listing[:baths].blank?
          next_flag = false
          info_doc = nil
          details_right = d_doc.css('.details-right').first
          if details_right && details_right.children.present?
            details_right.children.each do |child|
              if next_flag
                info_doc = child
                break
              end
              if child['class'] == 'residence-information'
                next_flag = true
              end
            end
            if info_doc
              info_text = info_doc.children.map{|s| s.text.strip}
              {'bed' => :beds, 'bath' => :baths}.each do |k, v|
                info_text.each_with_index do |text, index|
                  if text.downcase.include? k
                    listing[v] = info_text[index + 1]
                    break
                  end
                end
              end
            end
          end
        end
        retrieve_broker d_doc, listing
        retrieve_agents d_doc, listing
        retrieve_images(d_doc, listing)
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(".listing-agents .listing-agent").each do |listing_agent|
          agent = {}
          agent_url = get_agent_url(listing_agent) if listing_agent.present?
          agent_url.present? ? agent_doc = get_agent_doc(agent_url) : agent_doc = nil
          if agent_doc
            agent = {}
            agent[:name] = agent_doc.css(".agent-bar .photo-bar h2").text.strip
            agent_info = agent_doc.css(".agent-detail").text.split("\r").reject{|a|a==""}
            agent_tel = ""
            agent_info.each do |info|
              agent[:email] = info.strip if info.match(/@/)
              agent_tel = info.match(/Tel\: ([\d\-\(\)\s]+)/)
              agent[:tel] = agent_tel[1].gsub(/\D/, "").strip if agent_tel.present?
            end
            agent[:website] = agent_url
            src_origin_url = agent_doc.css(".agent-bar .photo-bar img")
            if src_origin_url.present?
              agent[:origin_url] = abs_url src_origin_url.attr("src").value
            end
            agent[:introduction] = agent_doc.css(".biography .lang-en").text.strip
            agents << agent
          end
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  "Halstead Property",
          website: domain_name,
          introduction: %q{Halstead Property is one of the largest and most visible residential real estate brokerage firms in New York. Headquartered at 499 Park Avenue, the firm has 1,200 sales and rental agents throughout prime retail offices in New York, New Jersey and Connecticut. Halstead Property boasts seven offices in Manhattan including the Upper East Side, Upper West Side, East Side, SoHo, Greenwich Village, Harlem and Washington Heights as well as six offices in Brooklyn. In addition, Halstead has offices in Riverdale, the Hamptons, Metro New Jersey, the Hudson Valley and Fairfield County, Connecticut.
Founded in 1984 by Clark P. Halstead and Diane M. Ramirez, Halstead Property is based on the simple guiding principle that the mission of a service company must indeed be service. The company quickly established themselves as the most innovative real estate firm in New York by being the first to establish ground floor, retail storefronts as offices and by developing a strategic 'triangle' growth plan that started with an Upper Eastside office and then quickly expanded to the Westside and Downtown. Halstead was one of the first firms to have offices in the key market areas of Manhattan. The two executives also recognized the important role that a technologically sophisticated environment could play in the conduct of a service-based business in a rapidly evolving economy. As a result, Halstead became recognized as a leading firm that provides their clients and customers with real tools and resources - as well as boasting some of the most talented agents and executives in the industry.
In 2001, Halstead Property joined the distinguished family of real estate-related companies owned by Terra Holdings, adding formidable, additional dimensions of talent, capability and capacity to its strengths. Terra Holdings is the standard-bearer of a number of great New York real estate traditions dating from 1873. Its companies and principals, who include David A. Burris, Kent M. Swig, Arthur W. Zeckendorf and William Lie Zeckendorf, carry forward corporate and family heritages long preeminent in residential and commercial real estate development, ownership and management, as well as a variety of associated services.}
        }
      end

      def retrieve_images(doc, listing)
        listing[:images] = []
        imgdocs = doc.css('.media-bar img')
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['src'].sub(/\?.+$/, ''))} if imgdoc['src'] =~ /l\.jpg/
        end
        listing
      end
    end
  end
end
