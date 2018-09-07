module Spider
  module Philadelphia
    class Maxwellrealty < Spider::Philadelphia::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '#resultsList .listing'
        @listing_image_css = 'head meta[property="og:image"]'
        @listing_callbacks = {
          image: ->(img){
            url = abs_url(img['content'])
            if url.include?('default')
              nil
            else
              url.gsub(/\?.+/, '')
            end
          }
        }
      end

      def domain_name
        'http://www.maxwellrealty.com/'
      end

      def page_urls(opts={})
        opts[:flags] ||= %w{rents sales}
        opts[:page] ||= 30
        urls = []
        opts[:flags].each do |flag|
          flag_i = get_flag_id(flag)
          if flag == 'rents'
            flag = ['RENTAL']
            prices = [500, 1000, 1500, 2000, nil]
          else
            flag = ['SINGLE', 'CONDO']
            prices = [50000, 150000, 200000, 350000, nil]
          end
          prices.each_with_index do |price, index|
            price_str = ""
            if index == 0
              next
            elsif price.nil?
              price_str = "minprice/#{prices[index - 1] + 1}/"
            else
              price_str = "minprice/#{prices[index - 1] + 1}/maxprice/#{price}/"
            end
            (1..opts[:page]).each do |i|
              flag.each do |fg|
                urls << ["http://www.maxwellrealty.com/listings/pgn/#{i}/propertytype/#{fg}/#{price_str}areas/46661/", flag_i]
              end
            end
          end
        end
        urls
      end

      def get_listing_url(simple_doc)
        link = simple_doc.css('.street a').first
        abs_url(link['href'])
      end

      def retrieve_detail(doc, listing)
        infos = doc.css('#listingInfo')
        listing[:title] = infos.css('#addressValue').text.split('#').first.try(:strip)
        listing[:unit]  = infos.css('#addressValue').text.strip.split('#')[1]
        listing[:zipcode] = infos.css('#zipValue').text.strip
        listing[:listing_type] = infos.css('#listingTypeValue').text.strip
        listing[:price] = infos.css('#priceValue').text.strip.gsub(/\D/, '')
        if infos.css('#listingDateValue').text.strip.downcase == 'active'
          listing[:status] = 0
        else
          listing[:status] = 1
        end
        property_infos = doc.css('#propertyInfo')
        listing[:beds] = property_infos.css('#bedValue').text.strip
        listing[:baths] = property_infos.css('#fullbathsValue').text.to_i + 0.5 *  property_infos.css('#halfbathsValue').text.to_i
        listing[:sq_ft] = property_infos.css('#squareFeetValue').text.strip
        listing[:description] = doc.css('#comments #remarksValue').text.strip
        listing[:amenities] = doc.css('#applianceValue').text.split(",").map(&:strip)

        profile_info = doc.css('#profileCard')
        if profile_info.present?
          listing[:contact_tel] = profile_info.css('.tel').first.text.strip.gsub(/\D/, '')
          listing[:contact_name] = profile_info.css('#profileName').text.split('-').first.strip #'Phillyapartmentco' #self.class.to_s
        end
        # listing[:contact_tel] ||= '2155466000'
        office_name = doc.css('#listingOfficeValue').first.try(:text) || 'Maxwell Realty'
        listing[:contact_name] ||=  office_name
        listing[:broker_name] ||= office_name
        listing[:amenities] = doc.css('#applianceValue').text.split(",").map(&:strip)
        if latlng = doc.css('.rightcolumn script')[2]
          latlng = latlng.text.match(/VELatLong\((.+)\)\,/)
          if latlng
            listing[:lat] = latlng[1].split(',').first
            listing[:lng] = latlng[1].split(',').last
          end
        end
        # retrieve_broker(doc, listing)
        #else
        #return nil
        #end
        listing
      end

      # def retrieve_broker doc, listing
      #   broker = {}
      #   broker[:name] = doc.css("#listingOfficeValue").text.strip
      #   listing[:broker] = broker
      # end

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
