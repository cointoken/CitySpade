module Spider
  module NYC
    class Bigapplenyc < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "table.forumline .row3 a"
        @check_url = ->(url){
          url.include?("id=")
        }
      end

      def domain_name
        'http://bigapplenyc.com/'        
      end

      def page_urls(opts = {})
        urls = []
        flag_i = get_flag_id("rent")
        url = "http://bigapplenyc.com/property_management/index.php?search_type=&text=&page=quick_search&"
        urls << [url + "go_to_page=0", flag_i]
        urls
      end

      def get_listing_url(simple_doc)
        abs_url 'property_management/' + simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        details = doc.css('table tr')
        hash = {}
        details.each do |tr|
          tds = tr.css('td')
          if tds.size == 2
            hash[tds[0].text.strip.underscore.remove(/\W/)] = tds.last.text.strip
          end
        end
        listing[:title] = hash['fulladdress']
        listing[:city_name] = hash['area']
        listing[:raw_neighborhood] = hash['neighborhood'] == '-' ? nil : hash['neighborhood']
        listing[:beds] = hash['beds'].to_f
        listing[:baths] = hash['baths'].to_f
        listing[:price] = hash['rent'].gsub(/\D/, '')
        listing[:unit] = hash['apartment']
        listing[:listing_type] = hash['buildingtype']
        listing[:no_fee] = true
        listing[:contact_name] = "Big Apple Management, LLC"
        listing[:contact_tel] = "2129475656"
        listing[:broker] = {
          name: "Big Apple Management, LLC", 
          tel: "2129475656",
          email: "apts@bigapplenyc.com",
          street_address: "347 Fifth Avenue, Suite 1201",
          zipcode: "10016",
          website: domain_name,
          introduction: %q{We are conveniently located directly across from The Empire State Building on Fifth Avenue, between 33rd and 34th Street.}
        }
        description = doc.css("p.MsoNormal").text.strip
        listing[:description] = description
        listing
      end

      def retrieve_images(doc, listing, opt={})
        return nil if listing.blank?
        listing[:images] = []
        content = doc.css("td.content script").text
        content.split('SLIDES.add_slide(s)').map{|s|
          if s.match(/(http\:\/\/\S+)/)
            src = s.match(/(http\:\/\/\S+)/)[1] unless s.match(/\.gif\Z/)
            listing[:images] << {origin_url: src} unless src.blank?
          end
        }
        listing
      end

    end
  end
end
