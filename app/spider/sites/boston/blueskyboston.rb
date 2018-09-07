module Spider
  module Boston
    class Blueskyboston < Spider::Boston::Base
      def initialize(accept_cookie: true)
        super
        @simple_listing_css = '.zrental-listing .zrental-data .zrental-address a'
        #@listing_image_css = '.jb-panel-detail .jb-dt-main-frame .jb-dt-main-image img'
        #@listing_callbacks[:image] =-> (img) {
        #}
      end

      def domain_name
        "http://blueskyboston.com/"
      end

      def page_urls(opts={})
        urls = []
        flag_i = 1
        20.times do |num|
          urls << [abs_url("rent/?rentpage=#{num + 1}"), flag_i]
        end
        urls
      end

      def get_listing_url(simple_doc)
        abs_url simple_doc['href']
      end

      def get_real_beds(str)
        str.split(/\s/).first.to_number
      end

      def retrieve_detail(doc, listing)
        entry_title = doc.css("#content .page .entry-title").text.split(',')
        listing[:title] = entry_title.first
        if entry_title.size > 2
          unit = entry_title[1].remove(/Unit/).strip if entry_title[1]
          listing[:unit] = unit.split(" ")[0] if unit && unit =~ (/\D{0,2}\d/)
          listing[:zipcode]  = entry_title.last.remove(/\D/)
        end
        listing[:price] = doc.css("#zrental-primary-data #zrental-price").text().
          split("/")[0].gsub(/\D/, "") unless doc.css("#zrental-primary-data #zrental-price").text.split("/").blank?
        listing[:neighborhood_name] = doc.css("#zrental-primary-data tr")[1].css('td .zrental-primary-data-values').text.strip unless doc.css("#zrental-primary-data tr")[1].blank?
        listing[:beds] = get_real_beds(doc.css("#zrental-primary-data tr")[2].css(
          "td .zrental-primary-data-values").text) unless doc.css("#zrental-primary-data tr")[2].blank?
        listing[:baths] = doc.css("#zrental-primary-data tr")[3].css(
          ".zrental-primary-data-values").text unless doc.css("#zrental-primary-data tr")[3].blank?
        sq_ft = doc.css("#zrental-primary-data tr")[4]
        if sq_ft
          listing[:sq_ft] = sq_ft.css('td.zrental-primary-data-values').text.strip
        end
        amenities = doc.css("#zrental-fields").css("tr td").map do |td|
          td.text.gsub(/\s/, "")
        end
        amenities = amenities.reject(&:empty?)
        amenities.pop(2)
        amenities.shift
        listing[:amenities] = amenities
        latlng = doc.css("#zrental").css("script")
        if latlng.present?
          lat = latlng[0].text().match(/ws_lat=\'([\d|\.|-]+)\';/)
          lng = latlng[0].text().match(/ws_lon=\'([\d|\.|-]+)\';/)
        else
          listing = {}
          return
        end
        listing[:lat] = lat[1] unless lat.blank?
        listing[:lng] = lng[1] unless lng.blank?
        listing[:contact_name] = doc.css(".zpress-aboutme-widget-brokerage_name").text || "Blue Sky Realty"
        listing[:contact_tel] = doc.css(".zpress-aboutme-widget-phone .mobile-hidden").text.gsub(/\D/, '') || "6178791507"
        listing[:description] = doc.css("#zrental-description-text").text.strip
        retrieve_broker(doc, listing)
        listing
      end

      def retrieve_broker(doc, listing)
        listing[:broker] = {
          name: "Blue Sky Realty",
          tel: "6178791507",
          email: "Pete@BlueSkyBoston.com",
          street_address: "1622A Beacon st #205 Brookline",
          zipcode: "02446",
          website: domain_name,
          introduction: "I am the owner & broker of Blue Sky Realty in Washington sq Brookline. A Brookline kid born and raised, I attended Brookline High School and then college down the road at Boston University. I worked at a rental brokerage during school and the years since my graduation in 2010. In 2013 I started my own Real Estate Brokerage firm in Brookline with the goal to provide the landlords, property managers, and prospective tenants with a high quality of service and knowledge . I’d be happy to serve you in anyway possible so please to not hesitate to contact me."
        }
      end

      def retrieve_images(doc, listing)
        if image_url = get_image_url(listing)
          res = get image_url
          return listing unless res.code.to_i == 200
          xml = Nokogiri::XML(res.body)
          listing[:images] = []
          xml.css('image').each do |img|
            listing[:images] << {origin_url: img['imageURL']} unless img['imageURL'].include?('no-photos-available')
          end
        end
        listing
      end

      def get_image_url(listing)
        path = (listing[:url] || '').strip.split('/').compact.last
        id = (path || '').split('-')[1]
        if id
          "http://www.blueskyboston.com/wp-content/mu-plugins/zillow-rentals/client-assist.php?action=GetPhotosXML&rentjuice_id=#{id}"
        else
          nil
        end
      end
    end
  end
end
