module Spider
  module NYC
    class ForestCity < Spider::NYC::Base
      def initialize
        super
        @ghery_url = "http://streeteasy.com/building/new-york-by-gehry/"
        @ghery_listing_index_page = Nokogiri::HTML(open("http://streeteasy.com/building/new-york-by-gehry/"))
        @ghery_listing_table = @ghery_listing_index_page.css(".listings_table_container").css(".nice_table.building-pages").css("tbody")

        @dekalb_url = "http://streeteasy.com/building/dklb-bkln"
        @dekalb_listing_index_page = Nokogiri::HTML(open("http://streeteasy.com/building/dklb-bkln"))
        @dekalb_listing_table = @dekalb_listing_index_page.css(".listings_table_container").css(".nice_table.building-pages").css("tbody")

        @two_building_table = [@ghery_listing_table, @dekalb_listing_table]
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
        listing[:title] = location_match.post_match
        listing[:unit] = location_match.pre_match[1..location_match.pre_match.length-1]
        if listing[:title] == "8 Spruce Street"
          listing[:city_name] = "New York"
          listing[:state_name] = "New York"
          listing[:url] = "http://streeteasy.com" + listing_pull.css("a")[0]['href']
          listing[:zipcode] = "10038"
          listing[:contact_tel] = "2128772220"
          listing[:description] = "One of the Tallest Residential Towers in North America by one of the most acclaimed architects of our time, Frank Gehry.Throughout the 6th, 7th, and 8th floors, residents have exclusive access to 22,000 square feet of indoor and outdoor health, wellness, social, and entertainment amenity spaces. These amenities, together with an extensive range of concierge and lifestyle services, offer residents an experience found only in world-class hotels and resorts. On the southern side of the 6th floor the first of the building's two terraces is outfitted with grills, cafe seating, and dining cabanas with picnic tables. From this terrace residents will enjoy stunning views of Cass Gilbert's classic Woolworth building. The adjacent game room is outfitted with custom designed seating by Gehry.On the 7th floor a 50-foot pool is set within a skylit space surrounded by a series of glass doors that retract fully, creating a seamless integration with the building's wraparound sundeck. Overlooking City Hall Park to the north, a large drawing room with multiple seating areas and a grand piano is located adjacent to a private dining room. Both are available for private events that can be served from a chef's demonstration and catering kitchen. A 3,300 square foot state-of-the-art fitness center with a view of the Brooklyn Bridge and a spa treatment suite are also located on the 7th floor. The 8th floor offers group fitness, Boxing Studio, and private training studios, a Library with a well-curated selection of books and periodicals, a Tween's Den, a Children's Playroom, and a Screening Room with Gehry-designed amphitheatre seating that can be reserved for private events. Apartment Features:Gehry's design resulted in over 200 unique floor plans that bring the drama of the dynamic exterior wall movement into residents' private spaces. In the places where the facade undulates, the residential windows also move out into space into the apex of the folds creating free-form bay windows that are fitted with seating or left open to accommodate uniquely shaped dining or reading niches. All interior finishes and fixtures have been selected by Gehry, including cabinetry crafted in his signature honey-colored vertical grain Douglas Fir."
          listing[:amenities] = ["Gym","Swimming Pool", "Children's Playroom", "Doorman", "Package Room", "Elevator", "Terrace"]
          listing[:images] = [{origin_url: "https://c1.staticflickr.com/1/596/23081501516_809a62a290_o.png"},{origin_url: "https://c1.staticflickr.com/1/780/22484876684_4718f1b766_o.png"},{ origin_url: "https://c2.staticflickr.com/6/5718/23081561176_a2b1098c09_o.png"},{ origin_url: "https://c1.staticflickr.com/1/568/22689332957_ca5dc9c7d6_o.png"},{ origin_url: "https://c1.staticflickr.com/1/610/22484989054_9c464d56fc_o.png"}]
        elsif listing[:title] == "80 Dekalb Avenue"
          listing[:city_name] = "Brooklyn"
          listing[:state_name] = "New York"
          listing[:zipcode] = "11201"
          listing[:contact_tel] = "2128772220"
          listing[:url] = "http://streeteasy.com" + listing_pull.css("a")[0]['href']
          listing[:description] = "Rising 36 stories in the heart of Fort Greene, DKLB BKLN’s striking glass and metal façade has become an architectural icon set in one of the most sought-after neighborhoods in Brooklyn. Spacious and bright studio, one- and two-bedroom residences offer spectacular city and river views, 9 to 11 foot high ceilings, designer kitchens, oversized closets, luxurious baths, and washers and dryers in every home. DKLB BKLN is one of the first green rental buildings in Brooklyn and is Silver LEED certified, making it easy to live eco-friendly. Overlooking Fort Greene Park and minutes from 11 subway lines, the Farmer’s Market, shops and restaurants on DeKalb Avenue, and BAM, DKLB BKLN is at the center of all that Fort Greene has to offer. 24 Hour Doorman On-site Parking Garage Landscaped Sundeck On-site Valet Service Bike Room 5,000sf Resident’s Amenity Space Featuring: Resident’s Lounge Fireplace Entertaining Kitchen Library State of the art Fitness Center Yoga Studio Screening Room Washers/Dryers in each Residence R, Q, B, M, A, C, G, 4, 5, 2, 3 Subway Lines.on DeKalb Avenue, and BAM, DKLB BKLN is at the center of all that Fort Greene has to offer."
          listing[:amenities] = ["Gym","Doorman","Elevator","Live-in Super"]
          listing[:images] = [{origin_url: "https://c1.staticflickr.com/1/717/23119188341_27a07726e1_o.png"},{origin_url: "https://c1.staticflickr.com/1/740/22485093194_497a96c09e_o.png"},{origin_url: "https://c1.staticflickr.com/1/617/22689443188_5dfd1e7bb1_o.png"},{origin_url: "https://c1.staticflickr.com/1/687/23094084302_4328ef5940_o.png"}]
        end

        if listing_pull.css('.hidden-xs').last.text.include?('ft²')
          listing[:sq_ft] = listing_pull.css('.hidden-xs').last.text.gsub(/\D/, '').to_f
        end

        if (/bed/) === listing_pull.css(".address").text
          matchText = (/bed/).match(listing_pull.css(".address").text)
          listing[:beds] = matchText.pre_match[matchText.pre_match.length-2]
        end
        if (/bath/) === listing_pull.css(".address").text
          matchText = (/bath/).match(listing_pull.css(".address").text)
          listing[:baths] = matchText.pre_match[matchText.pre_match.length-2]
        end
        listing
      end

      def listings(options={})
        @two_building_table.each do |building_grep|
          building_grep.css("tr").each do |listing_pull|
            listing = {}
            listing[:flag] = 1
            listing[:no_fee] = true
            listing[:is_full_address] = true
            listing[:contact_name] = "Forest City"
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
