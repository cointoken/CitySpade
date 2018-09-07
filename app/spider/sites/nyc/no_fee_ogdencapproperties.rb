module Spider
  module NYC
    class Ogdencapproperties < Spider::NYC::Base
      ## get listings from nestiolistings
      include Spider::Sites::Nestiolistings

      def initialize
        super
        @simple_listing_css = ".units-list "
        @listing_callback= {
          title: ->(title){
            title.split(/\s\s\s\s+/).last
          },
          available: ->(_) { true }
        }
      end

      def domain_name
        'http://www.ogdencapproperties.com/'
      end

      def nestiolistings_url
        "https://nestiolistings.com/widget/units/?layout=&min_rent=&max_rent=&date_available_before=&key=6035213d-e1dc15409fb7c461ff59-002470a8625d&version=2.2"
      end

      def base_listings_url
        "http://www.ogdencapproperties.com/property-listings.html"
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'Ogden CAP Properties, LLC',
          street_address: '545 Madison Avenue New York, NY',
          website: domain_name,
          tel: '2122895000',
          state: 'NY'
        }
      end
      def retrieve_contact detail, listing
        contact = detail.css('.viewing-instructions').text.strip
        contacts = contact.split('Contact')
        if contacts.size == 2
          listing[:contact_name] = contacts.first.split(',').first.remove('Agents:').strip
          listing[:contact_tel] = contacts.last.remove(/\D/)
        end
        listing[:contact_name] ||= listing[:broker][:name]
        listing[:contact_tel] ||= listing[:broker][:tel]
      end
    end
  end
end
