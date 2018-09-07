module Spider
  module NYC
    class Almarealty < Spider::NYC::Base
      ## get listings from nestiolistings
      include Spider::Sites::Nestiolistings
      def initialize
        super
        @simple_listing_css = ".units-list "
        @listing_callback = {
          contact_name: ->(name) {
            if name.size > 8 && name.include?(' ')
              name
            else
              'Alma Realty Corp'
            end
          },
          images: ->(imgs){
            imgs.select{|img| img[:origin_url].include? 'placeholder-thumb'}
          }
        }
        @state_name = nil
      end

      def domain_name
        'http://www.almarealty.com'
      end

      def nestiolistings_url
        "https://nestiolistings.com/widget/units/?layout=&min_rent=&max_rent=&date_available_before=&key=6514eaa310192f-163ee291ca3d8d-5a2d112b2dd2&version=2.1.1"
      end

      def base_listings_url
        'http://www.almarealty.com/listings/new/'
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'Alma Realty Corp',
          street_address: '31-10 37th Avenue, Suite 500 L.I.C., NY 11101',
          website: 'http://www.almarealty.com/listings/new/',
          tel: '7182670300',
          state: 'NY'
        }
      end
      def retrieve_contact detail, listing
        contact = detail.css('.viewing-instructions').text.strip
        if contact.present?
          listing[:contact_name] = contact.split('(').first
          listing[:contact_tel] = contact.split('(').last.remove(/\D/)
        end
        listing[:contact_name] ||= listing[:broker][:name]
        listing[:contact_tel] ||= listing[:broker][:tel]
      end
    end
  end
end
