module Spider
  module NYC
    class NestioGuidancenyc < Spider::NYC::Base
      ## get listings from nestiolistings
      include Spider::Sites::Nestiolistings

      def initialize
        super
        @simple_listing_css = nil
      end

      def domain_name
        'http://www.guidancenyc.com/'
      end

      def nestiolistings_url
        'https://nestiolistings.com/widget/units/?layout=&min_rent=&max_rent=&date_available_before=&sort=building&exclusives=true&page=1&key=1ab61d6857b14644bd9258df60631831&version=2.5'
      end

      def listings opt = {return_attrs: :url}
        super opt
      end

      def base_listings_url
        'http://www.guidancenyc.com/'
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'Guidance Realty NYC',
          website: domain_name,
          tel: '2125952300',
          email: 'rentals@guidancenyc.com',
          state: 'NY'
        }
      end
    end
  end
end
