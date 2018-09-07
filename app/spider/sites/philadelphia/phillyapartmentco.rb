module Spider
  module Philadelphia
    class Phillyapartmentco < Spider::Philadelphia::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '.Renters_details_box'
        @listing_image_css = '#gallery ul.ad-thumb-list li a'
        @listing_callbacks = {
          image: ->(img){
            abs_url(img['href'])
          }
        }
      end

      def domain_name
        'http://www.phillyapartmentco.com/'
      end

      def base_url(flag = nil)
        'http://www.phillyapartmentco.com/renter/free-results?fsid=CqzDC1NrCSAIuQDJ'
      end

      def page_urls(opts={})
        opts[:flags] ||= %w{rents}
        opts[:page] ||= 30
        urls = []
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)
          opts[:page].times do |i|
            urls << [base_url + ";pages=#{i}", flag_i]
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        link = simple_doc.css('.Renters_details_box_inner a').first
        abs_url(link['href'])
      end

      def retrieve_detail(doc, listing)
        listing[:title] = doc.css('#left_section h1').first.text.strip
        listing[:zipcode] = doc.css('#left_section h2').first.text[/\s(\d+)/, 1]
        desc_info = doc.css('#left_section .prop_desc').first
        desc_tables = desc_info.css('table')
        desc_tables.first.css('tr').each do |tr|
          tds = tr.css('td')
          if tds.size == 2
            case tds.first.text.strip.downcase
            when 'building type'
              listing[:listing_type] = tds.last.text.strip
            when 'full description'
              listing[:description] = tds.last.text.strip
            end
          end
        end
        if desc_tables.size > 1
          price_infos = desc_tables[1].css('tr.stdrow td')
          if price_infos.present?
            listing[:beds] = price_infos[1].text.strip
            listing[:baths] = price_infos[2].text.strip
            listing[:price] = (price_infos[4] || price_infos[3]).text.strip.gsub(/\D/, '')
          end
        end

        tables = desc_info.css('.imgdetal')
        if tables.size > 1
          table = tables[1]
          trs = table.css("tr")
          if trs.size > 2 && trs[0].text.include?('Bedrooms')
            listing[:listings] = []
            trs[1..-1].each do |tr|
              tds = tr.css('td')
              l = {beds: tds[1].text.strip, baths: tds[2].text.strip, price: (tds[3] || tds[4]).text.strip.gsub(/\D/, '')}
              listing[:listings] << l
            end
          end
        end
        listing[:amenities] = desc_info.css('.right_uf li, .right_cf li').map{|s| s.text.strip}
        listing[:contact_tel] = doc.css(".imgheadright span").text.strip.gsub(/\D/, '')
        listing[:contact_name] = 'Phillyapartmentco' #self.class.to_s
        retrieve_broker(doc, listing)
        listing
      end

      def retrieve_broker doc, listing
        listing[:broker] = {
          name: "The Philly Apartment Company",
          email: "info@phillyapartmentco.com",
          tel: "2154950070",
          street_address: "225 Arch Street First Floor Philadelphia",
          zipcode: "19106",
          website: domain_name,
          introduction: %q{Founded in 2004, The Philly Apartment Company is the largest residential leasing firm in Greater Philadelphia. We provide renters with an efficient, costfree way to find an apartment, while also providing owners a variety of highly effective services to market their properties to prospective renters.}
        }
      end

      #def retrieve_listing(simple_doc, flag_i)
      #listing = super
      #if listing
      #listing[:lat], listing[:lng] = eval(simple_doc['data-geo'])
      #end
      #listing
      #end
    end
  end
end
