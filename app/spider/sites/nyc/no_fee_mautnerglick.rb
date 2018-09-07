module Spider
  module NYC
    class Mautnerglick < Spider::NYC::Base

      def initialize(accept_cookie: true)
        super
        @simple_listing_css = "table#ctl00_ContentPlaceHolder1_ApartmentGrid tr.GridRow"
        @listing_image_css = "img#ctl00_ContentPlaceHolder1_PrimeImage"
        @listing_callbacks[:image] = ->(img){
          URI.join(domain_name, img['src']).to_s unless img['src'].include? 'No'
        }
      end

      #origin page site: http://www.mautnerglick.com/listings
      def domain_name
        'http://02e5a60.netsolhost.com/'
      end

      private :domain_name

      def page_urls(opts = {})
        [["http://02e5a60.netsolhost.com/ASP_Side/Apartment.aspx", 1]]
      end

      def get_listing_url simple_doc
        unit_id = simple_doc.css('td')[0].text
        abs_url "/ASP_Side/Apartment_Details.aspx?UnitID=#{unit_id}&PropAre=6"
      end

      def retrieve_detail doc, listing
        title = doc.css('#ctl00_ContentPlaceHolder1_FormView1_Label1').text.strip
        listing[:title] = title
        listing[:raw_neighborhood] = doc.css("#ctl00_ContentPlaceHolder1_FormView2_Area_NameLabel").text.strip
        listing[:city_name] = "Manhattan"
        content = doc.css("#ctl00_ContentPlaceHolder1_FormView1")
        trs = content[0].css('tr')
        opts = {}
        trs.each do|tr|
          tds = tr.css('td')
          if tds.size == 4
            opts[tds[0].text.strip.underscore.remove(/\W/).to_sym] = tds[1].text.strip
            td_last = tds.last.text.split(/\:|\n/).select{|s| s.present?}
            (0...(td_last.size / 2)).each do |i|
              opts[td_last[i * 2].strip.underscore.gsub(' ', '_').to_sym] = td_last[ i * 2 + 1]
            end
          end
        end
        listing[:beds] = opts[:bed].to_f
        listing[:baths] = opts[:bath].to_f
        listing[:price] = opts[:listing_price].split('.').first.remove(/\D/)
        listing[:sq_ft] = opts[:sq_ft]
        listing[:contact_tel] = opts[:phone].remove(/\D/)
        listing[:contact_name] ="Mautner-Glick Corp"
        listing[:broker] = {
          name: "Mautner-Glick Corp",
          email: "rentals@mautnerglick.com",
          tel: " 2122881999",
          website: "http://www.mautnerglick.com/"
        }
      end
    end
  end
end
