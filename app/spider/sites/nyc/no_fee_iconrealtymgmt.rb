module Spider
  module NYC
    class Iconrealtymgmt < Spider::NYC::Base

      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".result-image a"
        @listing_image_css = "#listing-thumbnails li a"
        @listing_callbacks[:image] = ->(img){
          abs_url img['href']
        }
      end

      def domain_name
        "http://www.iconrealtymgmt.com/"
      end

      def base_url
        domain_name + '/search?price=All&beds=All&location=All&visible=1&start=0&all=1'
      end

      private :domain_name, :base_url

      def page_urls(opts = {})
        [[base_url, 1]]
      end

      def get_listing_url simple_doc
        abs_url simple_doc["href"]
      end

      def retrieve_detail doc, listing
        ul = doc.css('#listing-other ul')
        opts = {}
        ul[0].css('li').each do|li|
          arr = li.text.split(':')
          opts[arr[0].underscore.remove(/\W/)] = arr[1]
        end
        listing[:price] = opts['price'].gsub(/\D/, '').to_i
        listing[:baths] = opts['bathrooms'].strip.to_f
        listing[:beds] = opts['unittype'].split(" ")[0].to_number.to_f
        location = doc.css("#listing-location div")
        title = location[0].text.strip
        listing[:title] = title
        listing[:raw_neighborhood] = location[2].text.strip
        listing[:contact_tel] = "2126757100"
        listing[:contact_name] = "Icon Realty Management"
        listing[:no_fee] = true
        listing[:broker] = {
          name: "Icon Realty Management",
          tel: "2126757100",
          email: "rentals@iconrealtymgmt.com",
          street_address: "419 Lafayette, 5th Floor", 
          zipcode: "10003",
          website: domain_name,
        }
        description = doc.css("#listing-description p").text.strip
        listing[:description] = description#.gsub(/\r\n/, "")
        listing
      end
    end
  end
end