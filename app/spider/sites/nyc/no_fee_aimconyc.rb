module Spider
  module NYC
    class Aimconyc < Spider::NYC::Base
      def initialize
        super
      end

      def domain_name
        'http://www.aimconyc.com/'
      end

      def self.json
        @@json ||= MultiJson.load RestClient.get('http://www.aimconyc.com/api/v3/corporations/homes/')
      end

      def self.enable_urls
        json.map{|l| new.abs_url "#details/#{l['id']}"}
      end

      def abs_url url
        URI.join(domain_name, url).to_s
      end

      def listings opt={}
        Aimconyc.json.each do |l|
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
        listing[:title] = json['address']
        listing[:baths] = json['bath']
        listing[:beds] = json['bed']
        listing[:city_name] = json['city']
        listing[:unit] = json['unit_number']
        listing[:raw_neighborhood] = json['neighborhood']
        listing[:url] = abs_url "#details/#{json['id']}"
        listing[:price] = json['rent'].remove(/\D/)
        listing[:description] = json['description']
        listing[:amenities] = json['amenities'].map{|s| s['name']}
        listing[:images] = json['galleries'].map{|s| s['photos'].map{ |img|{origin_url: img['image']} }}[0]
        # listing[:lat], listing[:lng] = json['center']['lat'], json['center']['lng']
        listing[:no_fee] = true
        listing[:is_full_address] = true
        listing[:flag] = 1
        listing[:contact_name] = 'Aimco APARTMENT HOMES'
        listing[:contact_tel] = '2124303692'
        listing[:broker] = {
          name: 'Aimco APARTMENT HOMES',
          tel: '2124303692',
          website: 'http://www.aimconyc.com/'
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
