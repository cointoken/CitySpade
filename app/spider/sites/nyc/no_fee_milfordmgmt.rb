module Spider
  module NYC
    class Milfordmgmt < Spider::NYC::Base
      include Spider::Sites::Nestiolistings
      def initialize
        super
        @simple_listing_css = ".units-list"
        @listing_callback = {
          title: ->(title) { title.strip.split(/\s{4,}/).last},
          url: ->(url) { url.sub('availabilities/#','availabilities/') }
        }
      end

      def domain_name
        'http://milfordmgmt.com/'
      end

      def base_listings_url
        'http://milfordmgmt.com/#/availabilities/'
      end

      def nestiolistings_url
        "https://nestiolistings.com/widget/units/?layout=&min_rent=&max_rent=&date_available_before=&hide_search=false&key=b48eeb9cfb3d4cb2b8f60aff1d341ced&version=2.2"
      end

      private :domain_name, :base_url

      def page_urls
        [[base_url, 1]]
      end

      def retrieve_broker listing
        listing[:broker] = {
          name: 'Milford Management',
          website: domain_name,
          tel: '2128427300',
          state: 'NY'
        }
      end
      def retrieve_contact detail, listing
        contact = detail.css('.viewing-instructions').text.strip
        if contact.present? && contact.include?('Agent:')
          cts = contact.split("\n")
          listing[:contact_name] = cts[0].remove('Agent:').strip#contact.split('(').first
          listing[:contact_tel] = cts[1].remove(/\D/)#contact.split('(').last.remove(/\D/)
        end
        listing[:contact_name] ||= listing[:broker][:name]
        listing[:contact_tel] ||= listing[:broker][:tel]
        listing[:description] = "For over 80 years under the Milstein Properties umbrella, Milford Management has been synonymous with the most exacting standards of excellence in the real estate industry. As a full-service organization, we offer our clients the greatest concentration of experience and talent in property management, development, and marketing. Milford Management is committed to providing the highest level of professional services to our residents with unwavering dedication and integrity; consequently, today, Milford Management stands as one of the largest managing agents of premier residential real estate in New York City."
      end
    end
  end
end
