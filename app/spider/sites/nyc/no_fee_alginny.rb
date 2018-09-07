module Spider
  module NYC
    class Alginny < Spider::NYC::Base
      def initialize
        super
      end

      def domain_name
        'http://www.alginny.com/'
      end

      def self.json
        @@json ||= MultiJson.load(RestClient.get('http://alginny.com/api/buildings/residentiallistings/listjson/?max_price=9000&format=json'))['results']
      end

      def self.enable_urls
        json.map do |l|
          URI.join("http://www.alginny.com/", 'new-york-residential-rental-properties/' + l['building_slug'] + "/##{l['apt_num']}").to_s
        end
      end

      def abs_url url
        URI.join(domain_name, url).to_s
      end

      def listings opt={}
        Alginny.json.each do |l|
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
        listing[:unit] = json['unit_number'] || json['apt_num']
        listing[:raw_neighborhood] = json['neighborhood']
        listing[:url] = abs_url abs_url 'new-york-residential-rental-properties/' + json['building_slug'] + "/##{json['apt_num']}"
        listing[:price] = json['price']
        # listing[:description] = json['description']
        # listing[:amenities] = json['amenities'].map{|s| s['name']}
        listing[:images] = (json['gallery_h165'] || []).map{|s| {origin_url: abs_url(s)} }
        # listing[:lat], listing[:lng] = json['center']['lat'], json['center']['lng']
        listing[:no_fee] = true
        listing[:is_full_address] = true
        listing[:flag] = 1
        listing[:contact_name] = 'ALGIN MANAGEMENT'
        listing[:contact_tel] = json['phone'].remove(/\D/)
        listing[:agents] = [{
          name: 'ALGIN MANAGEMENT',
          tel: '2122131727',
          email: json['agent_email'],
          website: 'http://alginny.com/'
        }]
        desc = get listing[:url]
        if desc.code == '200'
          doc = Nokogiri::HTML desc.body
          listing[:description] = doc.css('.mrgn_top .sidbarparagraph.sidebardesccolor p').text.strip
          listing[:amenities] = doc.css('.list-group.prprtymaincolor.prptylist.myriadprocond li').map{|s| s.text.strip}
        end
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
