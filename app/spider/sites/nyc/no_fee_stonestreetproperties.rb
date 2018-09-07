module Spider
  module NYC
    class Stonestreetproperties < Spider::NYC::Base

      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#main .details.bigger a"
        @listing_image_css = "#content #featured img"
        @listing_callbacks[:image] = ->(img){
          abs_url img['src']
        }
      end

      def domain_name
        'http://www.sspny.com/'
      end

      def page_urls(opts = {})
        [['http://www.sspny.com/availabilities', 1]]
      end

      private :domain_name

      def get_listing_url simple_doc
        abs_url simple_doc['href']
      end

      def retrieve_detail doc, listing
        obj = doc.css("span.bigger").text.split(',')
        listing[:title] = obj.first
        listing[:unit] = obj[1].strip
        trs = doc.css(".float_right.apt_info tr")
        opts = {}
        trs.each do|tr|
          tds = tr.css('td')
          if tds.size == 3
            opts[tds[0].text.strip.underscore.remove(/\W/).to_sym] = tds.last.text.strip
          end
        end
        listing[:price] = opts[:rent].remove(/\D/)
        listing[:beds] = opts[:bedrooms].to_f
        listing[:baths] = opts[:baths].to_f
        # listing[:status] = opts[:status].downcase == "active" ? 0 : 1
        listing[:contact_tel] = "6467953160"
        listing[:contact_name] = "Stone Street Properties"
        listing[:broker] = {
          name: "Stone Street Properties",
          tel: "6467953160",
          street_address: "148 Madison Ave, 5th Floor",
          zipcode: "10016",
          email: "leasing@sspny.com"
        }
      end
    end
  end
end
