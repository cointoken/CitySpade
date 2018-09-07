module Spider
  module NYC
    class Lclemle < Spider::NYC::Base
      ## get listings from nestiolistings
      include Spider::Sites::Nestiolistings

      def initialize
        super
        @simple_listing_css = ".units-list "
        @listing_callback= {
          title: ->(title){
            title.split(/\s\s\s\s+/).last
          },
          available: ->(avail) { true }
        }
      end

      def domain_name
        'http://lclemle.com/'
      end

      def nestiolistings_url
        "https://nestiolistings.com/widget/units/?layout=&min_rent=&max_rent=&date_available_before=&key=fd83041454a66516-262dc104c-1e965dcd9b66611&version=2.1.1"
      end

      def base_listings_url
        'http://lclemle.com/rentals/'
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'LC LEMLE REAL ESTATE GROUP',
          street_address: '177 EAST 87TH STREET, SUITE 501, NEW YORK, NY 10128',
          website: domain_name,
          email: 'rentals@lclemle.com',
          tel: '2122574822',
          state: 'NY'
        }
      end
    end
  end
end
