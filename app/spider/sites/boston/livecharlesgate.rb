module Spider
  module Boston
    class Livecharlesgate < Spider::Boston::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = 'h1.listing-address'
        @listing_image_css = 'img.bt-listing__gallery__image'
        @listing_callbacks = {
          image: ->(img){
            img['data-lazy'] if img['data-lazy'] !~ /comingsoon/i
          }
        }
        @listing_agent_css = "a.agent-thumb-link"
      end

      def domain_name
        'http://www.livecharlesgate.com/'
      end

      def base_url(flag)
        if flag.start_with?('sale')
          'http://www.livecharlesgate.com/results/?__hstc=58604661.6be52a2985c6731be8ca804ffd838de3.1400960434667.1401313861037.1401323186704.4&__hssc=58604661.1.1401323186704&__hsfp=703527432&custom=40762'
        else
          'http://www.livecharlesgate.com/results/?__hstc=58604661.6be52a2985c6731be8ca804ffd838de3.1400960434667.1401313861037.1401323186704.4&__hssc=58604661.1.1401323186704&__hsfp=703527432&custom=40762&proptype=RN'
        end
      end

      def login!
        param = {
          Email: 'myhours2@gmail.com',
          Password: '2343253254' }
        login_url = abs_url('/visitor/login/')
        get login_url, param
      end

      def page_urls(opts={})
        login!
        opts[:flags] ||= %w{rents sales}
        opts[:sales_page] ||= 130
        opts[:rents_page] ||= 100
        urls = []
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)
          res = get(base_url(flag))
          if res.code == "200"
            nums = Nokogiri::HTML(res.body).css(".js-pagination-total").text.gsub(/\D/, "").to_i
            pages = nums / 10
            if pages != 0
              flag == "sales" ? opts[:sales_page] = pages : opts[:rents_page] = pages
            end
          end
          (0...opts["#{flag}_page".to_sym]).each do |i|
            urls << [base_url(flag) + "&pageIndex=#{i}", flag_i]
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        link = simple_doc.css('a').first
        abs_url(link['href'])
      end

      def retrieve_detail(doc, listing)
        # agent = doc.css('.listing-footer .agent-info-block').first

        listing[:title] = doc.css('span[itemprop="streetAddress"]').first.text#.try(:text).try :strip
        if listing[:title]
          if listing[:title].include? '#'
            listing[:unit] = listing[:title].split('#').last.gsub(/\,/, '').strip.split("\n\t").first.strip
          end
          if listing[:unit].blank? && listing[:title].include?(',')
            units = listing[:title].split(',')
            if units.size == 2 && units.last.length < 4
              listing[:unit] = units.last
            end
          end
          listing[:title] = listing[:title].strip.split(/#|\,/).first.strip.gsub(/\s\s+/, ' ').gsub(/\,/, '')
        end
        return if listing[:title].blank?

        listing[:zipcode] = doc.css('span[itemprop="postalCode"]').first.try(:text).try(:strip)
        # if agent
        #   tel = agent.css('[itemprop="telephone"]').first
        #   listing[:contact_tel] = tel.text.gsub(/\D/, '') if tel
        #   listing[:contact_name] = agent.css('.agent-name').text.strip
        # end
        #neigh = doc.css('.info-box.callout-box li').first
        #if neigh && neigh.css('.info-box-label').text.downcase.include?('neighborhood')
        #listing[:raw_neighborhood] = neigh.css('.info-box-link').text.strip
        #listing[:raw_neighborhood] = nil if listing[:raw_neighborhood] =~ /other/i
        #end
        #desc = doc.css('.listing-section-content .remarks').first
        #if desc
        #listing[:description] = desc.text.sub('More', '').sub('Less', '')
        #end
        info = doc.css('#props-column .listing-property-overview')
        if info
          listing[:beds] = info.css('li.beds .attr-num').text
          listing[:baths] = info.css('li.baths .attr-num').text.to_i + info.css('li.half-baths .attr-num').text.to_i * 0.5
          listing[:sq_ft] = info.css('li.sqft .attr-num').text.gsub(/\D/, '')
          # listing[:unit]
          #unit = info.css('li.sqft-price .stat-value').last#.text.strip
          #if unit && unit.text.strip !~ /\$\d+$/
          #listing[:unit] = unit.text.strip
          #end
        end
        tds_h = {}
        doc.css("#props-column table tr").each do |tr|
          tds = tr.css("td")
          if tds.size == 2
            tds_h[tds.first.text.underscore.strip] = tds.last.text
          end
        end
        listing[:raw_neighborhood] = tds_h['area:']
        listing[:price] = doc.css('.uk-h1.uk-text-primary.uk-text-bold').text.gsub(/\D/, '')
        listing[:description] = doc.css(".uk-width-large-7-10>p").text.strip
        #amen = doc.css('.listing-sub-section.property .listing-sub-header').first
        #if amen && amen.text.downcase.include?('amenities')
        #amen = doc.css('.listing-sub-section.property ul').first
        #listing[:amenities] = amen.css('li').map{|s| s.text.strip} if amen
        #else
        #properties = doc.css('.listing-sub-section.property').children
        #i = -1
        #properties.each do |l|
        #i += 1
        #if l.text.downcase.include?('amenities')
        #if properties.size > i + 1
        #listing[:amenities] = properties[i + 1].css('li').map{|s| s.text.strip}
        #end
        #end
        #end
        #end
        lat = doc.css('meta[property="og:latitude"]').first
        lng = doc.css('meta[property="og:longitude"]').first
        if lat && lng
          listing[:lat], listing[:lng] = lat['content'], lng['content']
        end
        # broker = doc.css('.disclaimer-text').first
        # if broker
        #   #listing[:broker_name] = broker.children.first.text.split('courtesy of').last.strip
        #   listing[:broker_name] = listing[:contact_name]
        # end
        listing[:agents] = []
        doc.css(".bt-cell-align.bt-cell-align--middle.bt-cell-align--x-center").each_with_index{|xml, index|
          agent = {}
          agent[:name] = xml.css('.uk-h3').text.strip
          agent[:tel]  = xml.css("a.js-call-agent").first.try(:text).try :strip
          if agent[:tel].blank?
            tel = doc.css('a.js-call-agent')[index]
            agent[:tel] = tel.text.strip if tel
          end
          agent[:origin_url] = (xml.css("img").first || {})['src']
          agent[:tel].remove(/\D/) if agent[:tel]
          listing[:agents] << agent
        }
        if listing[:agents].present?
          listing[:contact_name] = listing[:broker_name] = listing[:agents].first[:name]
          listing[:contact_tel]  = listing[:agents].first[:tel]
        end
        # retrieve_agents(doc, listing)
        # retrieve_agent_broker(doc, listing)
        #p listing
        retrieve_images(doc, listing)
        listing
      end
      
      def retrieve_images(doc, listing)
        listing[:images] = Array.new
        doc.css(@listing_image_css ).each do |img|
         if img['src'].include?('photos') 
           listing[:images] << { origin_url: img['src'] }
         elsif img['data-lazy'].include?('photos') 
           listing[:images] << { origin_url: img['data-lazy'] }
         end
        end
        listing
      end

      #       def retrieve_agents doc, listing
      #         agents = []
      #         doc.css(".listing-agent").each do |listing_agent|
      #           agent = {}
      #           agent_url = get_agent_url(listing_agent)
      #           agent[:name] = listing_agent.css(".agent-info-block h3.agent-name").text.try(:strip)
      #           agent[:tel] = listing_agent.css(".listing-agent-phone-numbers").text.gsub(/\D+/, "") if listing_agent.css(".listing-agent-phone-numbers").text.present?
      #           agent[:website] = agent_url
      #           agent[:origin_url] = listing_agent.css(".listing-agent-img").attr("src").value if listing_agent.css(".listing-agent-img").present?
      # #            agent_email = agent_doc.css(".content-tagline.agent-info").text.strip.split("|")
      # #            agent[:email] = agent_email[1].strip if agent_email.size == 2
      #           agents << agent
      #         end
      #         listing[:agents] = agents.reject{|a| a=={}}
      #       end

      # def retrieve_agent_broker doc, listing
      #   agent = {}
      #   broker = {}
      #   sentance = doc.css("p.disclaimer-text").first.text.split("  ")[0].try(:strip) if doc.css("p.disclaimer-text").present?
      #   agent_and_broker = sentance.gsub(/Listing courtesy of/, "")
      #   agent[:name] = agent_and_broker.split("of")[0].strip
      #   broker[:name] = agent_and_broker.split("of")[1].strip[0..-2]
      #   listing[:broker] = broker
      #   listing[:agents] = [agent]
      # end

    end
  end
end
