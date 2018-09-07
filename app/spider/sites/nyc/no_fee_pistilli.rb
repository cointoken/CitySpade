module Spider
  module NYC
    class Pistilli < Spider::NYC::Base
      def initialize
        super
      end

      def domain_name
        'http://www.pistilli.com/'
      end

      def self.json
        @@json ||= MultiJson.load(RestClient.get('http://www.pistilli.com/service/search'))['listing']
      end
      def base_url
        'http://www.pistilli.com/availabilities/'
      end

      def self.enable_urls
        json.map do |l|
          URI::join('http://www.pistilli.com/availabilities/', URI.escape(l['listing']['friendly_url'])).to_s
        end
      end

      def listings opt={}
        Pistilli.json.each do |l|
          listing = retrieve_listing l
          next if !((listing[:title] || listing[:street_address]) || (listing[:lat] && listing[:lng]))
          listing[:city_name] ||= @city_name
          listing[:state_name] ||= @state_name
          check_title(listing)
          listing = check_flag(listing)
          if block_given?
            @logger.info listing
              yield listing
          else
            @logger.info listing
            listing
          end

        end
      end

      def retrieve_listing json
        listing = {}
        listing[:raw_neighborhood] = json['neighborhood']
        building = json['building']
        listing[:title] = building['address']
        listing[:raw_neighborhood] = building["neighborhood"]
        listing[:lat], listing[:lng] = building['lat'], building['lng']
        detail = json['listing']
        # listing[:images] = []
        if detail.present?
          listing[:price] = detail['price'].remove(/\D/)
          listing[:baths] = detail['bath']
          listing[:beds] = detail['bed']
          listing[:unit] = detail['unit']
          listing[:sq_ft] = detail['sqft']
          listing[:url] = abs_url detail['friendly_url'] + "##{listing[:unit]}" #"##{tail['id']}"
          listing[:description] = detail['description']
          listing[:images] = detail['photos'].map{|s| {origin_url: (abs_url s)} }
        end
        listing[:city_name] = json['borough']
        listing[:amenities] = json['specs']
        # listing[:lat], listing[:lng] = json['center']['lat'], json['center']['lng']
        listing[:no_fee] = true
        listing[:is_full_address] = true
        listing[:flag] = 1
        listing[:contact_name] = 'PISTILLI REALTY GROUP'
        listing[:contact_tel] = '7182041600'
        listing[:broker] = {
          name: 'PISTILLI REALTY GROUP',
          tel: '7182041600',
          website: domain_name
        }
        listing
      end

      def retrieve_detail(doc, listing)
        {}
      end

      def retrieve_images doc, listing
        {}
      end
    end
  end
end
