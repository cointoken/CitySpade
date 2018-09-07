module Spider
  module NYC
    class Kwnyc < Spider::NYC::Base
      def initialize(opts={})
        super
        @listing_agent_css = "tr td a.img"
      end

      def domain_name
        'http://kwnyc.com'
      end
      def base_url
        'http://kwnyc.com/_properties.cfm'
      end

      def init_params(flag)
        type = flag.starts_with?('sale')? 1 : 2

        {
          scroll:false,
          searchWith: nil,
          searchType: type,
          priceFrom:1000,
          priceTo:100000000,
          bedsFrom:0,
          bedsTo:28,
          bathFrom:0,
          bathTo:28,
          cat: nil,
          pType: nil,
          amenities: nil,
          status: nil,
          thisSort: 'price|desc',
          oh:false,
          new:true,
          change:false,
          vacation: false,
          furnished: false,
          nofee: false,
          address: nil,
          agent: nil,
          keyword: nil,
          special: 'undefined',
          searchParam: nil
        }
      end

      def more_params
        {scroll:true,
         aQuote: 'null',
         loaded:1,
         aProperties: '0,c_49962,c_51935,c_22286,c_54870,c_55835,c_22531',
         thisSort: 'price|desc',
         searchWith: nil}
      end

      private :domain_name, :base_url

      def page_urls(flag)
        urls = []
        urls[0] = init_params(flag)
        res = post(base_url, urls[0])
        if res.code == '200'
          docs = Nokogiri::HTML(res.body)
          propertys = docs.css('#availableProperties div.aProperty')
          index = propertys.size / 6
          # index = 50 if index > 40
          (1..index).each do |i|
            opt = more_params
            opt[:loaded] = i
            next unless propertys[(i * 6 - 6) .. (i * 6 - 1)].present?
            opt[:aProperties] = '0,' + propertys[(i * 6 - 6) .. (i * 6 - 1)].map{|div| div.text}.join(',')
            urls << opt
          end
        end
        urls
      end

      def listings(options={})
        %W(sale rent).each do |flag|
          @logger.info :sale, 'begin http get sale type'
          options.merge! :flag => flag
          page_urls(flag).each do |opt|
            @logger.info 'get url', base_url, opt
            res = post(base_url, opt)
            if res.code == '200'
              Nokogiri::HTML(res.body).css('div.span9.srLarge').each do |doc|
                listing = retrieve_listing(doc, base_url, options)
                next unless listing
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
        doc = doc.css('.largeProperty').first || doc
        section2 = doc.css('div.section2').first.text.strip
        section1 = doc.css('div.section1').first.text.strip
        section3 = doc.css('div.section3').first.text.strip
        listing[:listing_type] = (section2.match(/type\:\s?(\w+)/i) || [nil])[1]
        listing[:title] = doc.css('div.section1 h3').first.text.strip
        return false unless is_full_address?(listing[:title])
        listing[:flag] = get_flag_id(options[:flag])  if options[:flag].present?
        listing[:beds]  = (section1.match(/(\d+(\.5)?)\s?BD/)|| [0,nil]) [1]
        listing[:baths] = (section1.match(/(\d+(\.\d+)?)\s?BA/)|| [0,nil]) [1]
        listing[:sq_ft] = (section1.match(/(\d+(\.\d+)?)\s?SF/)|| [0,nil]) [1]
        listing[:price] = (section2.match(/\$\d+(\,\d{3})+/)||['0'])[0].gsub(/\$|\,/,'')
        listing[:contact_name] = doc.css('div.section3').first.css('h3').first.text.strip
        listing[:contact_tel]  = section3.match(/(\(\d+\)\s?)?(\d+\-)?\d+/)[0].gsub(/\D/, '')
        if doc.css('a').first.css('label').first.present? && doc.css('a').first.css('label').first.text.downcase.strip == 'rented'
          listing[:status] = 1
        end
        listing[:url]  = abs_url(doc.css('a').first['href'])
        listing[:zipcode] = get_zipcode_from_url(listing[:url])
        # listing[:neighborhood_name] = get_neighborhood_name_for_url(listing[:url])
        #listing[:images] = retrieve_images(doc, listing, url) if options[:image]
        res = get(listing[:url])
        if res.code == '200'
          doc_d = Nokogiri::HTML(res.body)
          get_detail(doc_d, listing)
        end
        listing
      end

      def get_detail(doc, listing)
        desc = doc.css("#descriptionBox")
        if doc.css(".container.detailsPage .span10 .block-white h1").present?
          unit = doc.css(".container.detailsPage .span10 .block-white h1")[0].text.split("#")
          listing[:unit] = unit[1].strip unless unit[1].blank?
        end
        if desc
          listing[:description] = desc.text.strip
        end
        amens = doc.css('#fAptA .amenityBullet').map{|t| t.text.gsub('•', '').strip}
        if amens.present?
          listing[:amenities] = amens
        end

        retrieve_open_houses(doc, listing)
        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        retrieve_images(doc, listing)
      end

      def retrieve_open_houses doc, listing
        ohInd = doc.css(".ohIndicator").text.split(/\r\n\s+\r\n/).reject(&:blank?)
        open_houses = []
        ohInd.each do |oh|
          if oh.match(/OPEN HOUSE:/i)
            date = Date.parse(oh.split("|").first.strip.split(":").last.strip)
            begin_time = oh.split("|").last.strip.split("-").first.strip
            end_time = oh.split("|").last.strip.split("-").last.strip
            begin_time = Time.parse(begin_time) if begin_time.match(/\d\:/)
            end_time = Time.parse(end_time) if end_time.match(/\d\:/)
            open_house = {open_date: date, begin_time: begin_time, end_time: end_time}
            open_houses << open_house
          end
        end
        listing[:open_houses] = open_houses if open_houses.present?
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(".block-white .contact .propertyContact table table").each do |listing_agent|
          agent = {}
          agent[:name] = listing_agent.css("tr td a img").first.attr("alt").strip
          agent_email = listing_agent.css("tr td a.emailAgent").first.attr("rel")
          agent[:email] = agent_email.split("|")[0] if agent_email.present?
          agent_url = get_agent_url(listing_agent)
          agent[:website] = agent_url if agent_url
          agent[:origin_url] = abs_url listing_agent.css("tr td a img").first.attr("src")
          agent_info = listing_agent.css("td").text.split("\r\n").reject{|a|a.blank?}
          agent_info.each do |info|
            agent[:tel] = info.gsub(/\D+/, "") if info.match(/[\d\-\(\)]+/)
          end
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  "Keller Williams NYC",
          tel: "2128383700",
          email: "info@kwnyc.com",
          website: domain_name,
          introduction: %q{Keller Williams NYC is the New York City master franchise of Keller Williams Realty International, the largest real estate company in North America with more than 100,000 agents. Locally, KWNYC has grown to more than 400 agents since its launch in 2011 and has been ranked in the top 10 for real estate agencies in NYC in many categories. The vast Keller Williams network affords our agents the opportuntiy to provide a full-service advisory real estate experience for the consumer.}
        }
      end

      def retrieve_images(doc, listing)
        listing[:images] = []
        imgdocs = doc.css('.media-bar img')
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['src'].gsub(/(\_(t|l))?/, ''))}# if imgdoc['src'] =~ /l\.jpg/
        end
        listing
      end

      def retrieve_images(doc, listing)
        imgdocs = doc.css('#slideshow_h img')
        listing[:images] = []
        imgdocs.each do |imgdoc|
          listing[:images] << {origin_url: abs_url(imgdoc['src'].sub('thumbs/', ''))} unless imgdoc['src'] =~ /no(.+)?photo/i
        end
        listing
      end

      def get_zipcode_from_url(url)
        return nil if url.blank?
        (URI(url).path.split('/')[2] || '').split('-').last
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
