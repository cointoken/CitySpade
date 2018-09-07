module Spider
  module NYC
    class Moinian < Spider::NYC::Base
      def initialize
        super
        @simple_listing_css = ".view-more a"
      end

      def domain_name
        'http://www.moinian.com/'
      end

      def base_url
        domain_name + "listings/apartments/page/"
      end

      private :domain_name, :base_url

      def page_urls opt={}  
        res = RestClient.get"http://www.moinian.com/listings/apartments/"
        doc = Nokogiri::HTML res.body
        pages = doc.css(".info-commercial-pro-listings .pagination-listings .num ul")[1].text.split("")
        pages.map do |i|
          url = URI.escape(base_url + i)
          [url, 1]
        end
      end

      def get_listing_url simple_doc
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        head = doc.css('.name-propertie')
        listing[:raw_neighborhood] = head.css('p.tk-pragmatica-web-condensed span').first.text.split(',').first.strip
        tl = head.css('p')[1]
        if tl
          listing[:title] = tl.children.first.text.strip.blank? ? tl.children[1].text.strip : tl.children.first.text.strip
        else
          return
        end
        listing[:contact_tel] = tl.children[4].text.remove(/\D/)
        listing[:contact_name] = head.css('a').last.text.split('.').first.strip
        detail = doc.css('.description-propertie p')
        listing[:beds] = detail.first.children[2].text.to_f
        listing[:price] = detail.last.children[1].text.remove(/\D/)
        if doc.css('.info-text-propertie .media-text').present?
          unit_txt = doc.css('.info-text-propertie .media-text').text
          unit = unit_txt.split('Unit')[1].split('.').first.try(:strip) if unit_txt.present? && unit_txt.split("Unit")[1].present?
        end
        listing[:description] = doc.css('.info-text-propertie p.media-text').text.strip
        listing[:broker] = {
          name: 'THE MOINIAN GROUP',
          street_address: '3 Columbus Circle 23rd floor New York, NY 10019',
          state: 'NY',
          tel: '2128084000',
          website: 'http://www.moinian.com/'
        }
        amen_css = doc.css('.has-tip')
        amens = []
        amen_css.each do|amen|
          amens << amen['title']
        end
        listing[:amenities] = amens
        listing
      end

      def retrieve_images doc, listing
        script = doc.css('.view-gal-vid script').text
        script = script.split('DOPNextGENThumbnailGalleryContent_gallery').last
        imgs_match = script.match(/(\[.+\])/)
        if imgs_match
          json = MultiJson.load imgs_match[1]
          listing[:images] = []
          json.each do |img|
            listing[:images] << {origin_url: img['Image']}
          end
        end
        listing
      end
    end
  end
end
