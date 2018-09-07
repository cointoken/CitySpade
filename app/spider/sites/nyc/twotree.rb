module Spider
  module NYC
    class TwoTree < Spider::NYC::Base
      def initialize
        super
        @mercedes_house_url = "http://streeteasy.com/building/mercedes-house"
        @listing_index_page = Nokogiri::HTML(open("http://streeteasy.com/building/mercedes-house"))
        @listing_table = @listing_index_page.css(".listings_table_container").css(".nice_table.building-pages").css("tbody")
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
        if listing[:title] == "550 West 54th Street"
          listing[:listing_type] = "rental"
          listing[:city_name] = "New York"
          listing[:state_name] = "New York"
          listing[:zipcode] = "10019"
          listing[:description] = "Mercedes House, New York most important new residential development, is changing the cityscape forever. From Two Trees Management Company and visionary architect Enrique Norten comes a luxury rental complex spiralling 30 stories above the city with unobstructed views of the Hudson River. A modern tower of glass and greenery. The good life is lived here. Bold design. Midtown convenience. Mercedes House is the address for life in style."
          listing[:amenities] = ["Gym","Swimming Pool", "Washer-Dryer", "Doorman", "Package Room", "Elevator", "Courtyard"]
          listing[:images] = [{origin_url: "https://c1.staticflickr.com/1/593/23082747982_0a7e0e8091_o.png"},{origin_url: "https://c2.staticflickr.com/6/5779/22678182098_09e0d51b33_o.png"},{ origin_url: "https://c2.staticflickr.com/6/5759/23096636455_368baa1435_o.png"},{ origin_url: "https://c1.staticflickr.com/1/769/23070580616_aeb3e34b92_o.png"},{ origin_url: "https://c2.staticflickr.com/6/5766/23070597236_a747943b4b_b.jpg"}]
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
        res = get(@mercedes_house_url)
        if res.code == '200'
          @listing_table.css("tr").each do |listing_pull|
            @logger.info 'get url', @mercedes_house_url
            listing = {}
            listing[:flag] = 1
            listing[:no_fee] = true
            listing[:is_full_address] = true
            listing[:url] = "http://streeteasy.com" + listing_pull.css("a")[0]['href']
            listing[:contact_name] = "TwoTree Management"
            listing[:contact_tel] = "6467973666"
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
        else
          []
        end
      end

    end
  end
end
