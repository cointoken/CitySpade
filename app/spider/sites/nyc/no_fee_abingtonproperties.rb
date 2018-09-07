module Spider
  module NYC
    class Abingtonproperties < Spider::NYC::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "#table-wrap a.apt-btn"
        @listing_image_css  = ".cycle-item>img"
        #@listing_callbacks[:image] = ->(img){
          #if img['src'].downcase.include?('uploads')
            #abs_url(img['src'])
          #end
        #}
      end

      def domain_name
        'http://www.abingtonproperties.com/'
      end

      def page_urls(opts)
        [['http://www.abingtonproperties.com/search/?apt_size=All&apt_area=All&apt_rent=All&apt_sort=rent', 1]]
      end

      def get_listing_url(simple_doc)
        abs_url '/index.php/apartments/apartment-details/' + simple_doc['href']
      end

      def retrieve_detail(doc, listing)
        listing[:title] = doc.css('.blackbox-body h1').first.text.strip
        listing[:unit] = doc.css('.blackbox-body h2').first.text.strip.remove(/apt/i)
        listing[:is_full_address] = true
        listing[:raw_neighborhood] = doc.css('.blackbox-body h2 span.dark').text.strip
        listing[:description]   = doc.css('.content .description').text.strip
        detail = doc.css('.detailbox .detailbox-body')
        lis = detail.css('li')
        li_hash = {}
        lis.each do |li|
          strong = li.css('strong').first
          if strong
            li_hash[strong.text.strip.underscore] = li.children.last.text.strip
          end
        end
        listing[:beds] = li_hash['bedrooms'].to_f
        listing[:baths] = li_hash['bathrooms'].to_f
        listing[:price] = li_hash['rent'].remove(/\D/)
        listing[:contact_tel] = li_hash['contact'].remove(/\D/)
        listing[:contact_name] = 'Abington Properties'
        listing[:no_fee] = true
        listing
      end
    end
  end
end
