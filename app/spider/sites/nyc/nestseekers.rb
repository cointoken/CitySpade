module Spider
  module NYC
    class NestSeekers < Spider::NYC::Base
      def initialize(opts={})
        super
        @listing_agent_css = "td a"
      end

      def domain_name
        'https://www.nestseekers.com'
      end
      def base_url(flag = 'Sales',area = nil)
        domain_name + "/#{flag.capitalize}/#{area}/"
      end
      private :domain_name, :base_url

      def page_urls(flag,area)
        if flag =~ /sale/i
          t_num = 20
        else
          if area == 'manhattan'
            t_num = 150
          else
            t_num = 20
          end
        end
        (0..t_num).map do |i|
          url = URI.escape(base_url(flag, area) + "?page=#{i}")
          url
        end
      end

      def listings(options={flags: ['Sales', 'Rentals'], areas: ['manhattan', 'queens', 'brooklyn']})
        (options[:flags] || %W(sales rentals)).each do |flag|
          @logger.info :sale, 'begin http get sale type'
          options.merge! :flag => flag
          (options[:areas] || ['manhattan', 'queens']).each do |area|
            page_urls(flag, area).each do |url|
              @logger.info 'get url', url
              res = get(url)
              if res.code == '200'
                Nokogiri::HTML(res.body).css('.searchPages#results tbody tr').each do |doc|
                  begin
                    listing = retrieve_listing(doc, url, options)
                  rescue => e
                    p e
                    next
                  end
                  check_title listing
                  @logger.info listing
                  listing[:city_name] ||= @city_name
                  listing[:state_name] ||= @state_name
                  listing[:status] = 1 unless listing[:is_full_address]
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
      end

      def retrieve_listing(doc, url = nil, options={})
        listing = {}
        listing[:flag]  = get_flag_id(options[:flag])  if options[:flag].present?
        url = doc.css('td.link a').first
        listing[:url] = url["href"]
        broker_info_and_images(listing)
        # else
          # listing = {}
        # end
        listing
      end

      def retrieve_images(doc, listing)
        listing[:images] = []
        imgs = doc.css('#pictures').children.first
        imgs = doc.css('#pictures').children[1] unless ['div', 'pic-gallery'].include? imgs.name
        if imgs && imgs['pics']
          imgs = MultiJson.load(imgs['pics'])
          (imgs['aptpics'] || []).each do |img|
            listing[:images] << {origin_url: img['full'] }  if img['full']
          end
        end
        listing
      end

      def get_detail(doc, listing)
        address = doc.css("#description.two.span6 address")
        title_and_unit = address.children[0].text.split("Apt:").map &:strip
        listing[:title] = title_and_unit[0].split(",")[0]
        listing[:unit] = title_and_unit[1] if title_and_unit[1].present?
        listing[:zipcode] = address.children[1].text.remove(/\D/)
        hash = {}
        trs = doc.css("#description.two.span6 div div table.info tr")
        trs.each do|tr|
          if tr.children.size == 2
            th = tr.css('th').text.strip.underscore.remove(/\W/).to_sym
            td = tr.css('td').text.strip
            hash[th] = td
          end
        end
        listing[:listing_type] = hash[:type]
        listing[:beds] = hash[:bedrooms].split(/\s*[A-z]/)[0].to_f if hash[:bedrooms].present?
        listing[:baths] = hash[:bathrooms].to_f if hash[:bathrooms].present?
        listing[:sq_ft] = hash[:area].remove(/\D/) if hash[:area].present?
        financial = doc.css("#description.two.span6 #financials table.info tr.price")
        if financial.present? && financial.children.size == 2
          listing[:price] = financial.children[1].text.split("-")[0].remove(/\D/)
        end
        listing[:neighborhood_name] = doc.css("#description.two.span6 div a").last.text.strip if doc.css("#description.two.span6 div a").last.present?
        descrip = doc.css('#description .text').first
        if descrip
          listing[:description] = descrip.text.strip
        else
          listing[:description] ||= doc.css('.text p').first.try(:text)
        end
        amen = doc.css('#description .amenities ul').first
        if amen
          listing[:amenities] = amen.css('li').map{|l| l.text.strip}
        else
          listing[:amenities] = doc.css('.text ul li').map{|l| l.text.strip}
        end
        listing
      end

      def broker_info_and_images(listing)
        res = get(listing[:url])
        if res.code == '200'
          doc = Nokogiri::HTML(res.body)
          get_detail(doc, listing)

          retrieve_agents(doc, listing)
          retrieve_broker(doc, listing)
          retrieve_images(doc, listing)

          doc = doc.css('#agent td.tight').first
          div = doc.css('div')[3]
          return unless doc && div
          listing[:contact_name] = doc.css('a').first.text.strip
          listing[:contact_tel]  = div.text.gsub(/\D/, '')
          listing
        end
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css("#agent tr").each do |listing_agent|
          agent = {}
          agent_url = get_agent_url(listing_agent)
          agent[:name] = listing_agent.css("td div strong").text.strip
          agent[:tel] = listing_agent.css("td div div").text.gsub(/\D+/, "") if listing_agent.css("td div div").text.match(/[\d\.]+/)
          agent[:email] = listing_agent.css(".email a").text.try(:strip)
          agent[:website] = agent_url
          agent[:origin_url] = listing_agent.css("td a img.thumbnail").attr("src").value if listing_agent.css("td a img.thumbnail")
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Nest Seekers International",
          tel: "8003304906",
          email: " info@nestseekers.com",
          zipcode: "10017",
          street_address: "415 Madison Avenue",
          website: domain_name,
          introduction: %q{In less than 10 years Nest Seekers has formed into a powerful full service brokerage sales and marketing firm leading the industry in New York City, the Hamptons, Miami and Beverly Hills.

With 15 storefront and office locations strategically located in high net worth markets and over 500 professionals and staff, we bring your property to market expeditiously and with enormous outreach.

Engaging our firm will employ our ever-growing leading-edge online proprietary platform generating over 2,000,000 absolute unique visitors per year and over 300,000 fans on our social networking sites.

Nest Seekers International is a pioneering firm on the cutting edge of ideas, concepts, marketing, and technology constantly, reinventing the standard of service and delivering superior performance as a fully integrated marketing and management firm.

Our professionals are frequently featured as experts on highest rated media outlets such as CNBC, BBC, Bloomberg, Wall Street Journal, New York Times and on real estate reality shows.

Always at the forefront of performance and technology, we are one of the fastest-growing real estate firms in the world, with several billion dollars in gross sales. We are not only committed to providing extraordinary service and exceptional results but also to remaining years ahead of the curve.

Our three branches merge to provide an unprecedented, vertical, full spectrum approach to every aspect of real estate. From concept to completion, we are there to navigate you through every step of conceptualizing, creating, and off-loading any real estate adventure.

Creativity, ingenuity, quality and passion in service and craft are the fundamentals to our success and growth.}
        }
      end

    end
  end
end
