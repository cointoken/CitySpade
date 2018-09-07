module Spider
  module NYC
    class Olnick < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "li ul.clearfix"
        @listing_image_css  = "#slideshow a.loadgallery"
        @get_url_args = 2
      end

      def domain_name
        'http://www.olnick.com/'
      end

      def page_urls(opts)
        [
          ['http://www.olnick.com/api?type=search-listing&listing_type=10&building=6109&min_rent=&max_rent=&field_bedrooms_value=All&field_bathrooms_value=All' ,1]
        ]
      end

      def get_listing_url(simple_doc, listing)
        li1 = simple_doc.css('li.col-1 .inner')
        li1s = li1.children
        listing[:raw_neighborhood] = li1s[0].text.strip
        listing[:title] = li1s[-2].text.split(/apt\#/i)[0].strip
        listing[:unit] = li1s[-2].text.split(/apt\#/i)[1].strip
        li2 = simple_doc.css('li.col-2 .inner')
        li2s = li2.children
        if li2s.size < 5
          listing = {}
          return nil
        end
        listing[:beds] = li2s[0].text.to_f
        listing[:baths] = li2s[2].text.to_f
        listing[:sq_ft] = li2s[4].text.to_i
        li3 = simple_doc.css('li.col-3 .inner')
        listing[:price] = li3.text.split('Available').first.split('.').first.gsub(/\D/, '')
        li5 = simple_doc.css('li.col-5 .inner')
        li5s = li5.children
        listing[:contact_name] = li5s[0].text.strip
        listing[:contact_tel] = li5s[-1].text.gsub(/\D/, '')
        listing[:agents] ||= [{name: listing[:contact_name],
                               email: li5s[2].text.strip,
                               tel: listing[:contact_tel]
        }]
        abs_url simple_doc.css('a.btn-details').first['href']
      end

      def retrieve_detail(doc, listing)
        listing[:description] = doc.css("#node_unit_residential_full_group_details_holder .field-item[property=\"content:encoded\"]").text.strip
        listing[:amenities] = doc.css(".detailtab #tab1 li.sm-col-6 ul li").map{|s| s.text.strip}
        listing[:broker] = {
          name: 'Olnick Management',
          tel: '2128352400',
          street_address: '135 East 57th St, 22nd Floor, New York, NY 10022',
          website: 'http://www.olnick.com/',
          state: 'NY'
        }
        listing
      end

    end
  end
end
