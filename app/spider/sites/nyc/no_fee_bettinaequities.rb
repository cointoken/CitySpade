module Spider
  module NYC
    class Bettinaequities < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#results tr.data"
        @listing_image_css  = ".left img"
      end

      def domain_name
        'http://www.bettinaequities.com/'
      end

      def page_urls(opts)
        [[base_url, 1]]
      end

      def base_url
       'http://www.bettinaequities.com/building.php?Neighborhood=-1&Building=-1&Rent=-1&Size=-1'
      end

      def get_listing_url(simple_doc)
        id = simple_doc['id']
        [base_url + "##{id}", 'http://www.bettinaequities.com/ajax.php', to_post_param(id)]
      end

      def to_post_param id
        {json: "{\"fn\":\"createDetails\",\"args\":[\"#{id}\"]}"}
      end

      def retrieve_detail(doc, listing)
        trs = doc.css('.center tr')
        hash = {}
        trs.each do |tr|
          tds = tr.css('td')
          if tds.size == 2
            key = tds.first.text.remove(':').split('/').last.underscore.to_sym
            hash[key] = tds.last.text.strip
          end
        end
        listing[:title] = hash[:address]
        # listing[:status] = hash[:status] == 'Avaliable' ? 0 : 1
        listing[:raw_neighborhood] = hash[:neighborhood]
        listing[:beds] = hash[:bedrooms].to_f
        listing[:baths] = hash[:baths].to_f
        listing[:unit] = hash[:unit].split('/').last.strip
        listing[:price] = hash[:rent].split('.').first.remove(/\D/)
        listing[:amenities] = hash[:amenities].split(',').map(&:strip) << hash[:pets]
        listing[:is_full_address] = true
        listing[:contact_name] = 'Bettina Equities'
        listing[:contact_tel]  = '2127443330'
        listing[:broker] = {
          name: 'Bettina Equities',
          email: 'info@bettinaequities.com',
          state: 'NY',
          tel: '2127443330',
          website: 'http://www.bettinaequities.com/'
        }
        listing
      end
    end
  end
end
