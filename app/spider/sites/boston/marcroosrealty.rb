module Spider
  module Boston
    class Marcroosrealty < Spider::Boston::Base
      ## same for properrg
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = ".ygl_listing .ygl_info .ygl_info_title a"
        @listing_image_css = ".ygl_photo_thumbs li img"
      end

      def domain_name
        "http://marcroosrealty.com/"
      end

      def page_urls(opts={})
        urls = []
        opts[:flags] = %w{rents}
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)
          if flag_i == 1
            60.times do |num|
              urls << [abs_url(
                "rentals/?city_neighborhood=&min_rent=&max_rent=&beds_from=&beds_to=&pet=&search_rentals.x=59&search_rentals.y=23&search_rentals=Search&pageIndex=#{num + 1}&pageCount=10"
              ), flag_i]
            end
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc["href"]
      end

      # listings中才有标题，所以覆写
      def retrieve_listing(simple_doc, flag_i)
        url = get_listing_url(simple_doc)
        listing = {flag: flag_i, url: url}
        listing[:title] = simple_doc.children.text()
        res = get(url)
        if res.code == '200'
          doc = Nokogiri::HTML(res.body)
          retrieve_detail(doc, listing)
          retrieve_broker(doc, listing)
          retrieve_images(doc, listing)
          listing
        else
          nil
        end
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "Marc Roos Realty",
          email: "info@marcroosrealty.com",
          tel: "6172368600",
          street_address: "484 Commonwealth Ave",
          zipcode: "02215",
          website: domain_name,
          introduction: "Welcome to Marc Roos Realty. Our company was founded in 1998 on a commitment to professionalism and customer service that remains the core of our business philosophy today. Our website is a reflection of our belief in customer service and providing an exceptional real estate experience.

Whether you are a first-time buyer or in the process of stepping up to your first rental, marcroosrealty.com is a great place to begin the process. We have made everything available to you 24/7 and only a click away – including information on over 10,000 properties for sale/rent and access to the brightest and most professional Sales/Rental Associates in the real estate business. Marc Roos Realty Associates are the reason clients continue to work with us transaction after transaction. Their knowledge and experience can guide you through the real estate process from log in to move in and help you with all of the details before, during and after the sale.

On behalf of everyone at Marc Roos Realty, I would like to thank you for choosing us to help you with your real estate needs. If you have any suggestions on how we can create an even better experience, or if you just want to share a real estate story with us, please contact us. We look forward to seeing you in the future on our website and in our offices. After all, the greatest compliment is your referral."
        }
      end

      def retrieve_detail(doc, listing)
        if listing[:flag] == 1
          hash = {}
          doc.css(".ygl_detail div div div").each do |div|
            span = div.css('span')
            if span.size == 2
              hash[span.first.text.remove(':').underscore.to_sym] = span.last.text.strip
            end
          end
          listing[:price] = hash[:rent].remove(/\D/) if hash[:rent].present?
          listing[:beds] = hash[:bedrooms].to_f
          listing[:baths] = hash[:bathrooms].to_f
          listing[:status] = (hash[:status] == 'ONMARKET' ? 0 : 1)
          latlng = doc.css("#ygl_tabpanel_map script").text().match(/maps\.LatLng\((.+)\)/)[1] if doc.css("#ygl_tabpanel_map script").text.match(/maps\.LatLng\((.+)\)/).present?
          if latlng.present?
            listing[:lat] = latlng.split(",")[0]
            listing[:lng] = latlng.split(",")[1].gsub(/\s/, "") if latlng.match(',').present?
          end
          listing[:description] = doc.css(".ygl_detail_desc p").text
          listing[:amenities]  = doc.css('.ygl_detail_featurelist td').map{|s| s.text.strip}.select{|s| s.present?}
          listing[:contact_name] = "MARCROOSREALTY"
          listing[:contact_tel] = doc.css(".mrrHeaderBx div span").text().split("|")[0].strip.gsub(/\D/, '')
        end
        listing
      end

    end
  end
end
