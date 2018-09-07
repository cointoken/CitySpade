module Spider
  module Feeds
    class RealtyMx < Spider::Feeds::Base
      class << self
        def read_obj
          RestClient.get 'http://www.realtymx.com/demo/admin/tools/cityspade.xml'#File.read Rails.root.join('db', 'cityspade.xml')
        end
        def nokogiri_xml
          @nokogiri_xml ||= Nokogiri::XML(read_obj)
        end
        def mls_name
          'RealtyMx'
        end
        def setup
          xmls = nokogiri_xml.xpath('//Listing')
          xmls = xmls.map{|xml| xml.to_hashie}
          mls_ids = xmls.map{|xml| xml.listing_details.mls_id}
          ids = MlsInfo.where(name: mls_name).where("mls_id not in (#{mls_ids.join(',')})").select(:listing_id).map(&:listing_id)
          if ids.size < Listing.realtymx.enables.size * 0.5 && Listing.realtymx.enables.size > 2000
            expireds = Listing.where(id: ids)
            expireds.update_all status: 1, updated_at: Time.now
          end
          objs = []
          xmls.sort_by!{|s| s.open_houses.present? ? 0 : 1}
          xmls.each do |xml|
            obj = retrive_listing_object_from_db(xml)
            #if obj.present? && (!obj.new_record? && obj.created_at < Time.now - 2.day)
              #attrs = {}
              #attrs[:status] = 0 if obj.expired?
              #if obj.raw_neighborhood.blank?
                #attrs[:raw_neighborhood] = xml.neighborhood.try(:name) || xml.neighborhood
                #attrs[:raw_neighborhood] = attrs[:raw_neighborhood].split(/\-|\/|\(|\&/).first.strip  if attrs[:raw_neighborhood]
                #attrs.delete :raw_neighborhood if attrs[:raw_neighborhood] && attrs[:raw_neighborhood].downcase == 'manhattan'
              #end
              #obj.update_columns(attrs) if attrs.present?
              #next
            #end
            # set listing enable
            obj.status = 0
            # next if !obj.new_record? && obj.created_at > (Time.now - 1.day)
            ## Location
            location = xml.location
            obj.street_address = obj.title =  location.street_address
            if location.display_address == 'Yes'
              obj.is_full_address = true
            else
              obj.is_full_address = false
            end
            next if obj.street_address.strip =~ /^XX/i
            obj.unit = location.unit_number
            obj.lat  = location.lat if location.lat
            obj.lng  = location.long if location.long
            obj.city_name = location.city
            obj.state_name = location.state
            obj.zipcode = location[:zip]
            obj.neighborhood_name = xml.neighborhood.try(:name) || xml.neighborhood
            obj.city_name = 'New York' if obj.city_name == obj.neighborhood_name
            obj.neighborhood_name = obj.neighborhood_name.split(/\-|\/|\(|\&/).first if obj.neighborhood_name && obj.neighborhood_name.downcase != 'manhattan'
            ## location end
            ## listing detail
            detail =  xml.listing_details
            if detail.status =~ /rent/i || detail.price.to_i < 50000
              obj.flag = 1
            end
            if detail.price.to_i > 100000
              obj.flag ||= 0
            end
            obj.url = detail.listing_url
            obj.price = detail.price
            obj.mls_info_id = detail.mls_id
            client_id = detail.client_id
            detail = xml.basic_details
            obj.beds = detail.bedrooms
            obj.baths = detail.bathrooms
            if detail.match(/\\n/).blank?
              obj.description = detail.description.gsub(/([\.\!]) ([A-Z\d])/) {|s| "#{$1}\r\n #{$2}" }.gsub(/\.(Contact)/i){|s| ".\r\n #{$1}"}
            end
            obj.listing_type = detail.property_type
            #obj.title = detail.title
            # listing detail end
            features = xml.rich_details.try(:additional_features)
            if features.present?
              obj.amenities = features.split(',').map(&:strip)
            end
            ## listing detail
            obj.detail_hash = {maintenance: xml.rich_details.maintenance} if xml.rich_details.try(:maintenance)
            # check listing is fee?
            check_is_fee obj, xml
            ## agent
            agent = xml.agent
            broker = xml.office
            obj.contact_name = "#{agent.first_name} #{agent.last_name}"
            obj.contact_tel  = (agent.office_line_number || agent.mobile_phone_line_number || broker.broker_phone).split(/[A-z]/)[0].gsub(/\D/, '')

            agent = Agent.get_from_realty_mx(xml.agent)
            next if agent.new_record?
            obj.agent_id = agent.id
            if obj.new_record?
              listing = Listing.get_listing_from_spider obj.slice(:title, :url, :price, :beds, :baths, :listing_type, :flag),
                'New York', neighborhood_name: obj.neighborhood_name, listing_type: obj.listing_type, zipcode: obj.zipcode,
                agent_id: obj.agent_id
              obj = listing if listing
            end
            if xml.open_houses && xml.open_houses.open_house.present?
              retrieve_open_house xml, obj
              #            else
              #              next
            end
            if obj.save
              pic_arrs = []
              if xml.pictures
                if xml.pictures.picture.is_a? Array
                  pic_arrs = xml.pictures.picture
                else
                  pic_arrs = [xml.pictures.picture]
                end
              end
              pic_arrs.each do |pic|
                next unless pic
                ListingImage.where(origin_url: pic.picture_url, listing_id: obj.id,
                 floorplan: pic.caption == "Floorplan").first_or_create
              end
              broker.mls_name = mls_name
              broker.mls_id = obj.mls_info_id
              broker.listing_id = obj.id
              broker.client_id = client_id
              broker.state ||= obj.state_name
              mls = MlsInfo.get_mls_info_id_from_xmlhash(broker)
              if mls && !agent.new_record?
                if agent.broker_id.blank?
                  agent.update_column :broker_id, mls.broker_id
                end
                obj.update_columns mls_info_id: mls.id, broker_id: (mls.broker_id || obj.agent.try(:broker_id))
                Listing.enables.where(mls_info_id: mls.id).where.not(id: obj.id).update_all status: 1, updated_at: Time.now
              end
            end
            ## images
            objs << obj
          end
          ## perfect the agents details
          complete_realty_mx_agents objs
          ## perfect the realty mx listings geo
          Listing.realtymx.where(status: 20).each do |l|
            l.status = 0
            l.save
          end

          BrokerLlsStatus.update_datas Date.today, 'RealtyMx'
        end
        def retrive_listing_object_from_db(listing)
          url = ListingUrl.where(url: listing.listing_details.listing_url).first
          if url
            url.listing
          else
            Listing.new
            # Hashie::Mash.new
          end
        end

        def check_is_fee(listing, xml)
          if xml.to_s =~ /no\-fee|no\s+fee/i
            listing[:no_fee] = true
          else
            listing[:no_fee] = false
          end
        end

        def complete_realty_mx_agents listings
          Listing.realtymx.enables.where.not(id: listings.map(&:id)).update_all status: 1, updated_at: Time.now
          listings.map(&:agent).uniq.compact.each do |agent|
            next if agent.origin_url.blank?
            match = agent.origin_url.match(/http:\/\/(.+\.com)/)# [1] if agent.origin_url.present?
            next unless match
            site = match[1]
            if agent.website.blank? or agent.introduction.blank?
              agent_id = agent.origin_url.match(/(\d+)\./)
              next unless agent_id
              website = "http://#{site}/index.cfm?page=agents&state=profile&id=#{agent_id[1]}" if agent_id.present?
              res = RestClient.get website
              if res.code.to_s == '200'
                obj = {website: website}
                doc = Nokogiri::HTML res.body
                Spider::Improve::Agent.send "realty_mx", doc, obj
                if obj.present?
                  agent.update_attributes obj
                end
              end
            else
              next
            end
          end
        end

        def retrieve_open_house xml, obj
          open_houses = xml.open_houses.open_house
          open_houses = [open_houses] unless Array === open_houses
          open_houses.map!{|open|
            h = {open_date: open.date, begin_time: open.start_time, end_time: open.end_time}
            h
          }
          #xml.open_houses.each do|oh|
          #if oh.present?
          #if oh.open_house.class == XmlHash
          #open_house = []
          #open_house.push(oh.open_house)
          #oh.open_house = open_house
          #end
          #oh.open_house.each do|o|
          #open_house = {}
          #open_house[:open_date] = Date.parse o.date
          #open_house[:begin_time] = Time.parse o.start_time
          #open_house[:end_time] = Time.parse o.end_time
          #open_houses << open_house
          #end
          #end
          #end
          obj.open_houses = open_houses
        end

      end
    end
  end
end
