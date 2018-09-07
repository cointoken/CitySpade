module Spider
  module NYC
    class Stribling < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @get_listing_lists = ->(body){
          Nokogiri::HTML MultiJson.load(body)['results']
        }
        @simple_listing_css = "li a.listing"
        @listing_image_css  = '.carousel-container li img'
        @listing_agent_css = '.contact-an-agent .agent'
      end

      def domain_name
        'http://www.stribling.com/'
      end

      def page_urls(opts)
        [['http://www.stribling.com/properties', 1, {rental: 1}], ['http://www.stribling.com/properties', 0, {rental: 0}]]
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        tls = doc.css(".title-bar-container h1").children.map(&:text).select{|s| s.present?}
        listing[:title] = tls.first
        listing[:raw_neighborhood] = tls[-1].strip if tls.size > 1
        hash = {}
        doc.css(".essential-information li").each do |li|
          key = li.css("em").text.strip
          value = li.children.last.text.strip
          if key != value && key.present? && value.present?
            hash[key.underscore] = value
          end
        end
        listing[:price] = hash['price:'].remove(/\D/)
        listing[:beds]  = hash['bedrooms:']
        listing[:baths]  = hash['bathrooms:']
        listing[:sq_ft] = hash['approx. sq. ft.:']
        listing[:listing_type] = hash['type']
        listing[:amenities] = doc.css(".features ul li").map(&:text).map(&:strip)
        listing[:description] = doc.css(".description>p").map{|s| s.text.strip}.join("\n")
        retrieve_agents(doc, listing)
        retrieve_broker(doc, listing)
        listing[:open_houses] = []
        doc.css("section.open-houses p").each do |p|
          children = p.children.map(&:text)
          if children.size == 2
            oh = children.last.strip
            if oh =~ /^\d/
              ohs = oh.split(' ', 2)
              dates = ohs.first.split('/')
              if dates.size == 3
                h = {}
                h[:open_date] = "#{dates[2]}-#{dates[1]}-#{dates[0]}"
                if ohs.size == 2
                  h[:begin_time] = ohs.last.split(/\–|\-/).first.strip
                  h[:end_time] = ohs.last.split(/\–|\-/).last.strip
                else
                  h[:begin_time] = "9 AM"
                  h[:end_time] = "6 PM"
                end
                listing[:open_houses] << h
              end
            end
          end
        end
        if listing[:agents].present?
          listing[:contact_name] = listing[:agents][0][:name]
          listing[:contact_tel]  = listing[:agents][0][:tel]
        end
        listing
      end

      def retrieve_agents doc, listing
        agents = []
        doc.css(@listing_agent_css).each do |listing_agent|
          agent = {}
          agent[:website] = abs_url listing_agent.css('a').first['href']
          agent[:name] = listing_agent.css(".name").text
          agent[:email] = listing_agent.css(".email-address").text.try(:strip)
          agent[:tel] = listing_agent.css('.phone-number').children.map(&:text).select{|s| s.size > 9}.first.try(:remove, /\D/)
          agent[:origin_url] = listing_agent.css('a img').first['src'] if listing_agent.css('a img').present?
          agents << agent
        end
        listing[:agents] = agents.reject{|a| a=={}}
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name:  " Stribling Private Brokerage",
          email: "info@stribling.com",
          website: domain_name,
          state: 'NY',
          introduction: %q{Stribling Private Brokerage is an advanced marketing program that provides sellers of truly exceptional properties with unique access to a global audience of ultra-high-net-worth buyers.}
        }
      end


      def get_title doc, listing={}
        listing[:title] = doc.css('.title-bar-container h1 span').text.strip.split(',').first
      end
    end
  end
end
