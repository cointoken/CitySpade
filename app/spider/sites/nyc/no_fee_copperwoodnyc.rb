module Spider
  module NYC
    class Copperwoodnyc < Spider::NYC::Base
      ## get listings from nestiolistings
      include Spider::Sites::Nestiolistings

      def initialize
        super
        @simple_listing_css = ".units-list "
      end

      def domain_name
        'http://copperwoodnyc.com/'
      end

      def nestiolistings_url
        'https://nestiolistings.com/widget/units/?layout=&min_rent=&max_rent=&date_available_before=&key=bcbee1dac00734e52f&version=2.1.1'
      end

      def base_listings_url
        'http://copperwoodnyc.com/search-apartments-no-fee-apartments-nyc/'
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'COPPERWOOD REAL ESTATE',
          street_address: '317 East 84th Street | New York, NY 10028',
          website: domain_name,
          tel: '2123901800',
          email: 'rentals@copperwoodnyc.com',
          state: 'NY'
        }
      end
    end
  end
end
