module Spider
  module Feeds
    class Tfc < Spider::Feeds::Base
      class << self
        def read_obj
          RestClient.get 'http://tfc.io/xml/cityspade.xml'#File.read Rails.root.join('db', 'cityspade.xml')
        end
        def nokogiri_xml
          @nokogiri_xml ||= Nokogiri::XML(read_obj)
        end
        def mls_name
          'tfc'
        end
        def setup
          xmls = nokogiri_xml.css('Listing')
          xmls = xmls.map{|xml| xml.to_hashie}
          ##mls_ids = xmls.map{|xml| xml.listing_details.mls_id}
          ##ids = MlsInfo.where(name: mls_name).where("mls_id not in (#{mls_ids.join(',')})").select(:listing_id).map(&:listing_id)
          ##expireds = Listing.where(id: ids)
          ##expireds.update_all status: 1
          current_time = Time.now
          broker_ids = []
          ids = []
          xmls.each do |xml|
            obj = Hash.new() #retrive_listing_object_from_db(xml)
            ## Location
            # set listing enable
            obj[:status] = 0
            location = xml.location
            obj[:street_address] = location.street_address
            if location.display_address == 'Yes'
              obj[:is_full_address] = true
            else
              obj[:is_full_address] = false
            end
            obj[:unit] = location.unit_number
            obj[:lat]  = location.lat if location.lat
            obj[:lng]  = location.long if location.long
            obj[:city_name] = location.city
            obj[:state_name] = location.state
            obj[:zipcode] = location[:zip]
            obj[:neighborhood_name] = xml.neighborhood.try(:name) || xml.neighborhood
            obj[:city_name] = 'New York' if obj[:city_name] == obj[:neighborhood_name]
            obj[:neighborhood_name] = obj[:neighborhood_name].split('/').first if obj[:neighborhood_name]
            ## location end
            ## listing detail
            detail =  xml.listing_details
            doc = listing_nokogiri_html detail
            retrieve_open_house doc, obj if doc.css(".intouch-block__hours").present?
            obj[:flag] = 1
            #if detail.status =~ /rent/i || detail.price.to_i < 50000
              #obj.flag = 1
            #end
            #if detail.price.to_i > 100000
              #obj.flag ||= 0
            #end
            if detail.listing_url
              obj[:url] = detail.listing_url
            else
              obj[:never_has_url] = true
            end
            obj[:date_listed] = detail.date_listed
            obj[:price]       = detail.price
            detail = xml.basic_details
            obj[:beds] = detail.bedrooms
            obj[:baths] = detail.bathrooms
            obj[:description] = detail.description
            obj[:listing_type] = detail.property_type
            obj[:title] = detail.title

            features = xml.rich_details.try(:additional_features)
            if features.present?
              obj[:amenities] = features.split(',').map(&:strip)
            end
            # listing detail end
            # check listing is fee?
            obj[:no_fee] = true
            ## agent
            agent = xml.agent
            obj[:contact_name] = "#{agent.first_name} #{agent.last_name}"
            obj[:contact_tel]  = (agent.office_line_number || agent.mobile_phone_line_number).split(/[A-z]/)[0].gsub(/\D/, '')

            agent = Agent.get_from_realty_mx(agent)
            obj[:agent_id] = agent.id
            listing = Listing.get_listing_from_spider(obj, 'New York') || Listing.new(obj)
            ids << listing.id unless listing.new_record?
            next if !listing.new_record? && listing.created_at > (Time.now - 1.day)
            if listing.update_attributes obj
              ids << listing.id
              pic_arrs = []
              if xml.pictures
                if xml.pictures.picture.is_a? Array
                  pic_arrs = xml.pictures.picture
                else
                  pic_arrs = [xml.pictures.picture]
                end
                if xml.pictures[:picture_url]["caption"] == "Floorplan"
                  pic_arrs << xml.pictures[:picture_url]
                end
              end
              pic_arrs.each do |pic|
                next unless pic
                ListingImage.where(origin_url: pic.picture_url, listing_id: listing.id, floorplan: pic[:caption] == "Floorplan" ? true : false).first_or_create
              end
              xml.office.state ||= obj[:state_name]
              broker = Broker.get_broker_from_hash(xml.office)
              if broker
                broker_ids << broker.id
                if agent.broker_id.blank?
                  agent.update_column :broker_id, broker.id
                end
                listing.update_columns broker_id: broker.id
              end
            end
            ## images
          end
          broker_ids.uniq!
          ids.uniq!
          if broker_ids.present?
            Listing.where(broker_id: broker_ids).where('updated_at < ?', current_time - 3.hour).update_all(status: 1)
            Listing.where(broker_id: broker_ids, id: ids).update_all(status: 0)
          end
        end

        def retrieve_open_house doc, obj
          arr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
          obj[:open_houses] = []
          hours = doc.css(".intouch-block__hours")[0].css("p")
          hours.each do|hour|
            open_dates = hour.children[0].text.split("-").map &:strip
            begin_and_end_time = hour.children[1].text
            begin_time = begin_and_end_time.split("-")[0]
            end_time = begin_and_end_time.split("-")[1]
            if open_dates.size == 2
              opt_1 = open_dates[0]
              opt_2 = open_dates[1]
              for i in arr.index(opt_1)..arr.index(opt_2) do
                open_date = Date.parse(arr[i])
                open_houses = {open_date: open_date, begin_time: Time.parse(begin_time), end_time: Time.parse(end_time), loop: true, next_days: 7}
                obj[:open_houses] << open_houses
              end
            else
              open_date = Date.parse(open_dates[0])
              open_houses = {open_date: open_date, begin_time: Time.parse(begin_time), end_time: Time.parse(end_time), loop: true, next_days: 7}
              obj[:open_houses] << open_houses
            end
          end
          obj[:open_houses]
        end

        def listing_nokogiri_html detail
          res = RestClient.get detail.listing_url
          doc = Nokogiri::HTML res.body
        end

      end
    end
  end
end
