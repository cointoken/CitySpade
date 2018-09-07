module Spider
  module Boston
    class Bushari < Spider::Boston::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '.property .row .body .title-price .title h2 a'
        @listing_image_css = '.property .content ul li img'
        @listing_callbacks[:image] = ->(img){
          abs_url(img['src'])
        }
      end

      def domain_name
        'http://www.bushari.com/'
      end

      def page_urls(opts)
        urls = []
        opts[:type] = %w{7 11 34}
        page_nums = [12, 18, 6]
        opts[:type].each_with_index do |type, index|
          page_nums[index].times do |index|
            url = index == 0 ? abs_url("properties/?filter_type=#{type}") :
              abs_url("properties/page/#{index+1}/?filter_type=#{type}&filter_sort_by=date&filter_order=DESC")
              urls << [url, 0]
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        overview = doc.css(".property-detail .overview .row .span3 table tbody tr")
        listing[:title] = doc.css("#main h1.page-header").text
        price        = get_listing_attr(overview, 'price')
        listing_type = get_listing_attr(overview, 'type')
        flag         = get_listing_attr(overview, 'contract') || ''
        neighborhood_name = get_listing_attr(overview, 'location')
        baths = get_listing_attr(overview, 'bath')
        beds  = get_listing_attr(overview, 'bed')
        sq_ft = get_listing_attr(overview, 'area')
        if price
          listing[:price] = price.gsub(/\D/, '')#overview[1].css("td").text().gsub(/[\s\,$]/, '')
        end
        listing[:listing_type] = listing_type
        listing[:flag] =  flag.downcase == 'sale' ? 0 : 1
        listing[:baths] = baths
        listing[:beds] = beds
        listing[:neighborhood_name] = neighborhood_name
        listing[:sq_ft] = sq_ft.gsub(/\D/, '') if sq_ft
        listing[:description] = doc.css(".property-detail p").text
        listing[:amenities] = doc.css(".property-detail .row .span12 .row ul li").
          collect{ |li| li.text }
        script = doc.css(".property-detail script").text
        latlng = script.match(/google\.maps\.LatLng\((.+)\)/)[1]
        latlng = latlng.gsub(/\s/, "").split(",")
        listing[:lat], listing[:lng] = latlng[0], latlng[1]

        # listing[:contact_name] = "Bushari Group"
        # listing[:contact_tel] = doc.css("table.contact tr")[0].css("td").text
        # agent = doc.css('.agent').first
        # if agent
        #   listing[:contact_name] = agent.css('.name').first.text
        #   listing[:contact_tel]  = agent.css('.phone').first.text.strip.sub(/\+\d+\s+/, '')
        # end
        broker = doc.css('#mlsPIN small').first
        if broker
          if broker.children.size > 1
            sentance = broker.children.last.text.split(' of ').last.strip
            agent_and_broker = sentance.split(" from ")
            if agent_and_broker.size == 2
              listing[:contact_name] = agent_and_broker[0].strip
              listing[:broker_name] = agent_and_broker[1].strip
            else
              listing[:contact_name] = agent_and_broker[0].strip
              listing[:broker_name] = agent_and_broker[0].strip
            end
          end
        end
        #retrieve_broker(doc, listing)
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Bushari Group",
          email: "info@bushari.com",
          tel: "16174500900",
          street_address: "234 Clarendon Street, 4th floor Boston",
          zipcode: "02116",
          website: domain_name,
          introduction: "Bushari Group Real Estate is a boutique, luxury real estate brokerage located in the heart of Boston’s Back Bay. With a focus on Boston luxury condos and luxury apartment rentals, our experienced and innovative agents are expert negotiators and extremely knowledgeable about the Boston luxury real estate market.

We know that our success is wholly based on the satisfaction of our clients. We built Bushari Group Real Estate on a strong ethical foundation and a commitment to form a forward-thinking Boston real estate company with an acute focus on exceptional customer service. Independently owned and operated, our agents have an acute knowledge of Boston luxury properties, luxury buildings and new developments."
        }
      end

      def get_listing_attr(attrs, attr)
        attrs.each do |doc|
          return doc.css('td').last.text if doc.css('th').text.downcase.include? attr
        end
        nil
      end

    end
  end
end
