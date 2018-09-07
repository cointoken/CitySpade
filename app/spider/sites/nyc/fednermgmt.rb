module Spider
  module NYC
    class FednerManagement < Spider::NYC::Base
      #The Epic and other buildings
      def initialize
        super
        @manhattan_park_url = "http://streeteasy.com/building/manhattan-park-10_40-river-road-new_york"
        @manhattan_park_index_page = Nokogiri::HTML(open("http://streeteasy.com/building/new-york-by-gehry/"))
        @manhattan_park_listing_table = @ghery_listing_index_page.css(".listings_table_container").css(".nice_table.building-pages").css("tbody")
      end

      def listing_info_grab(listing_pull, listing)
        #price
        price_string = listing_pull.css(".address").css("span").css(".price").text
        price_string = price_string[1..price_string.length]
        price_match = (/,/).match(price_string)
        price = price_match.pre_match + price_match.post_match
        listing[:price] = price.to_i
        #unit and street address
        location_match = (/- /).match(listing_pull.css(".address").css("a").text)
        listing[:title] = "30 River Road"
        listing[:city_name] = "New York"
        listing[:state_name] = "New York"
        listing[:zipcode] = "10044"
        listing[:description] = "Roosevelt Island’s skyline and river views, lush greenery, and relaxed atmosphere make it a distinctly desirable place to call home. Just four minutes from Manhattan via the Roosevelt Island Tramway, the community is almost entirely encircled by walks and promenades. Located in a waterfront neighborhood, Manhattan Park’s four rental buildings are clustered around a large, landscaped village green. The buildings luxurious amenities include 24-hour concierge service, 24-hour attended lobby, the Roosevelt Island Swim Club, complimentary 24-hour fitness center, five outdoor children’s playgrounds, and an adjacent parking facility."
        listing[:amenities] = ["Concierge", "Doorman", "Elevator", "Gym", "Roof Deck"]
        listing[:images] = [{}]
        listing[:contact_tel] = "2123084040"
        listing[:url] = "http://streeteasy.com" + listing_pull.css("a")[0]['href']
        listing[:unit] = location_match.pre_match[1..location_match.pre_match.length-1]
        if (/bed/) === listing_pull.css(".address").text
          matchText = (/bed/).match(listing_pull.css(".address").text)
          listing[:beds] = matchText.pre_match[matchText.pre_match.length-2]
        end
        if (/bath/) === listing_pull.css(".address").text
          matchText = (/bath/).match(listing_pull.css(".address").text)
          listing[:baths] = matchText.pre_match[matchText.pre_match.length-2]
        end
      end

      def listings(options={})
        @two_building_table.each do |building_grep|
          building_grep.css("tr").each do |listing_pull|
            listing = {}
            listing[:flag] = 1
            listing[:no_fee] = true
            listing[:is_full_address] = true
            listing[:contact_name] = "Manhattan Park"
            listing[:listing_type] = "rental"
            listing_info_grab(listing_pull,listing)
            next unless listing
            check_title listing
            if block_given?
              @logger.info listing
              yield(listing)
            else
              p listing
            end
          end
        end
      end
    end
  end
end
