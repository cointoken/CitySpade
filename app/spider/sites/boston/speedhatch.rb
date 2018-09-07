module Spider
  module Boston
    # class Bostonproperrealestate < Spider::Boston::Base
    class Speedhatch < Spider::Boston::Base
      def initialize(accept_cookie: true)
        super
        #@proxy_host ||= Settings.proxy_host
        #@proxy_port ||= Settings.proxy_port
        @simple_listing_css = 'li.listing .meta h3 a'
        @listing_image_css = '#gallery img'
        @listing_callbacks[:image] = ->(img){
          abs_url(img['src'])
        }
      end

      def domain_name
        'http://bostonproperrealestate.com/'
        'http://ag001517.speedhatch.com/'
      end

      def page_urls(opts={})
        opts[:flags] = %w{rents}
        urls = []
        opts[:flags].each_with_index do |flag, index|
          flag_i = get_flag_id(flag)
          if flag_i == 1
            100.times do |num|
              urls << [abs_url("rentals/page:#{num + 1}"), flag_i]
            end
          else
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc["href"]
      end

      def retrieve_detail(doc, listing)
        listing[:title] = doc.css("head title").text.split(/\,|\./).first
        listing[:price] = doc.css("#details .price strong").text.gsub(/\D/, "")
        listing[:beds] = doc.css("#details .beds").text.strip.split(/\s/).first
        listing[:baths] = doc.css("#details .baths").text.strip.split(/\s/).first
        listing[:sq_ft] = doc.css("#details .sqft").text.gsub(/\s/, "") unless doc.css("#details .sqft").blank?
        listing[:description] = doc.css("#description .content p").text.strip
        listing[:contact_name] = doc.css(".wrapper aside a")[0].attributes["title"].value() if doc.css(".wrapper aside a").present?
        listing[:contact_tel] = doc.css(".contact .phoneme").text.gsub(/\D/, '')
        script = doc.css('script').text
        if script
          if lat = script.match(/lat:((\d|\.|\-)+)\,/)
            listing[:lat] = lat[1]
          end
          if lng = script.match(/lng:((\d|\.|\-)+)\,/)
            listing[:lng] = lng[1]
          end
        end
        retrieve_broker(doc, listing)
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Boston Proper Real Estate",
          tel: "6172624500",
          email: "brokers@bostonproperrealestate.com",
          website: domain_name,
          street_address: "49 Gloucester St",
          zipcode: "02115",
          introduction: "Based in Boston’s historic Back Bay neighborhood, Boston Proper Real Estate embodies the spirit and hard-working values of the city of Boston.

          Our diverse team is united by a common goal…
To exceed every client’s expectations in the purchase, sale, and leasing of Boston real estate.

Whatever your goal or budget, our team is ready to help you realize your real estate objectives.

We strive to offer a smooth, painless experience to all of our clients, whether you are trading upto a new home in the city or you are a expat from another country with no experience in Boston Real Estate.

Our team is made up of seasoned veterans as well as some of Boston’s best emerging talent. From our offices just off Newbury Street at 49 Gloucester Street, we serve all of Boston’s most sought after areas, helping clients to find their perfect home in this “city of neighborhoods”.

"
        }
      end

    end
  end
end
