module Spider
  module NYC
    class Heraldtowers < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".content table tbody tr"
        @listing_image_css  = ".viewport .gallery-items img"
      end

      def domain_name
        'http://www.heraldtowers.com'
      end

      def base_url
        domain_name + "/availabilities/"
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def listings(options={})
        page_urls.each do |url_opt|
          flag_i = url_opt.last
          url    = url_opt.first
          @logger.info 'get url', url
          res = get(url)
          if res.code == '200'
            Nokogiri::HTML(res.body).css(@simple_listing_css).each_with_index do |doc, i|
              listing = retrieve_listing(doc, url, options)
              listing[:flag] = flag_i
              listing[:city_name] ||= @city_name
              listing[:state_name] ||= @state_name
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

      def retrieve_listing(doc, url, options)
        listing = {}
        listing[:title] = "50 W 34TH ST"
        listing[:street_address] = "50 W 34TH ST"
        listing[:zipcode] = "10001"
        listing[:unit] = doc.css(".unit .border-wrap").text.strip
        listing[:price] = doc.css(".rent .border-wrap").text.strip.gsub(/\D/, "")
        listing[:sq_ft] = doc.css(".size .border-wrap").text.strip
        listing[:beds] = doc.css(".type .border-wrap").text.strip.to_f
        listing[:baths] = doc.css(".baths .border-wrap").text.strip.to_f
        listing[:listing_type] = doc.css(".style .border-wrap").text.strip
        listing[:description] = %q{
          Herald Towers is ideally located in the heart of New York – Herald Square. Soaring 26 stories high, the building houses 690 luxury residential units with sweeping panoramic views of the city. Nestled at the crossroads where most of New York’s major subway lines converge, it is also only a block away from the PATH train and LIRR. Herald Towers offers the following features and amenities:

Studio, One-, and convertible Two-bedroom apartments graced with luxurious kitchens and bathrooms, and oversized closets.
Some Studios boast over 500 sq. ft, while some One-bedrooms are convertible to Two-bedrooms and also feature 2 full baths.
Panoramic city views; the building stands in the shadow of the iconic Empire State building
Penthouse apartments occupy the top floor, have spectacular views, and extra high ceilings
24-Hour Concierge
Newly renovated lobby, elevators, and hallways
In-house Dry Cleaners and Laundry Room
Internet Access and Cable TV Ready
Access to Fitness Center on Penthouse Level
Roof deck
        }
        retrieve_images listing
        retrieve_broker(doc, listing)
        listing[:contact_name] = listing[:broker][:name]
        listing[:contact_tel] = listing[:broker][:tel]
        listing[:url] = URI.escape "#{base_url}##{listing[:unit]}"
        listing[:no_fee] = true
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "HERALD TOWERS, LLC",
          website: domain_name,
          street_address: "50 W 34TH ST",
          zipcode: "10001",
          tel: "2127365700",
          introduction: %q{
            Herald Towers is ideally located in the heart of New York – Herald Square. Soaring 26 stories high, the building houses 690 luxury residential units with sweeping panoramic views of the city. Nestled at the crossroads where most of New York’s major subway lines converge, it is also only a block away from the PATH train and LIRR. Herald Towers offers the following features and amenities:

Studio, One-, and convertible Two-bedroom apartments graced with luxurious kitchens and bathrooms, and oversized closets.
Some Studios boast over 500 sq. ft, while some One-bedrooms are convertible to Two-bedrooms and also feature 2 full baths.
Panoramic city views; the building stands in the shadow of the iconic Empire State building
Penthouse apartments occupy the top floor, have spectacular views, and extra high ceilings
24-Hour Concierge
Newly renovated lobby, elevators, and hallways
In-house Dry Cleaners and Laundry Room
Internet Access and Cable TV Ready
Access to Fitness Center on Penthouse Level
Roof deck
          }
        }
      end

      def retrieve_images listing
        url = "http://www.heraldtowers.com/gallery/classic-apartments"
        listing[:images] = []
        res = RestClient.get(url)
        if res.code.to_s == "200"
          images = []
          images.push Nokogiri::HTML(res.body).css(@listing_image_css).first
          images.each do |img|
            listing[:images] << {origin_url: URI.escape(domain_name + img.attr("src"))} unless img.attr("src").blank?
          end
        end
      end
    end
  end
end
