module Spider
  module NYC
    class Ccmanagers < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "li.apartment_content_box a.btn"
        @listing_image_css  = ".content img"
        @listing_callbacks[:image] = ->(img){
          abs_url(img['src']) unless img['src'].downcase.include?('big')
        }
      end

      def domain_name
        'http://ccmanagers.com/'
      end

      def page_urls(opts)
        [['http://ccmanagers.com/rental-apartments/', 1]]
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        titles = doc.css('.wrapper h2')
        title = titles.first.children.first.text
        listing[:title] = title.split(',').first
        unit = doc.css('.wrapper .heading h1.title').first
        if unit && unit.text.downcase.include?('unit')
          listing[:unit] = unit.text.remove(/unit/i).strip
        end
        listing[:title] = listing[:title].split(',').first.strip #if listing[:title] =~ /\D+\s?\-\s?\d/
        if title.include? 'NY'
          listing[:city_name] = title.split(',')[1].strip
        end
        listing[:zipcode] = title.split(',')[-1].remove(/\D/)
        bbs = doc.css('.wrapper .element h2.color_394F59').first.text
        listing[:beds] = bbs.split('|').first.to_f
        listing[:baths] = bbs.split('|')[1].to_f
        listing[:price] = doc.css('.wrapper .element h2.color_394F59')[1].text.remove(/\D/)
        listing[:amenities] = doc.css('.wrapper .element li').map{|s| s.text.strip}.select{|s| s.present?}
        listing[:description] = doc.css('.wrapper .unit_description_wrapper').text.strip
        listing[:contact_name] = 'C+C APARTMENT MANAGEMENT LLC'
        listing[:contact_tel] = '2123483248'
        listing[:no_fee] = true
        listing
      end
    end
  end
end
