module Spider
  module Feeds
    class Idealpropertiesgroup < Spider::Feeds::Base
      class << self
        def spider
          @@spider ||= Spider::Base.new
        end
        def read_obj
          RestClient.get 'http://www.idealpropertiesgroup.com/feed/zillow'#File.read Rails.root.join('db', 'cityspade.xml')
        end

        def nokogiri_xml
          @nokogiri_xml ||= Nokogiri::XML(read_obj)
        end

        def mls_name
          'Ideal Properties Group'
        end

        def get_broker(xml={})
          Broker.find_and_update_from_hash(name: xml.office.brokerage_name, website: xml.office.broker_website, tel: xml.office.broker_phone.gsub(/\D+/, ""),
                                           email: xml.office.broker_email, zipcode: xml.office["zip"], street_address: xml.office.street_address, state: xml.office.state)
        end

        def get_agent(xml={}, broker)
          broker.agents.find_and_update_from_hash(name: [xml.first_name, xml.last_name].join(" "), email: xml.email_address, tel: xml.mobile_phone_line_number.try(:remove, /\D/),
                                                  fax_tel: xml.fax_line_number.try(:remove, /\D/), origin_url: xml.picture_url)
        end

        def get_open_houses(xml={}, obj)
          if xml.open_houses.present?
            open_date = Date.parse xml.open_houses.open_house.date.strip
            begin_time = Time.parse xml.open_houses.open_house.start_time.strip
            end_time = Time.parse xml.open_houses.open_house.end_time.strip
            oh = {open_date: open_date, begin_time: begin_time, end_time: end_time}
            obj.open_houses.where({open_date: open_date}).first_or_initialize.update(oh)
          end
        end

        def set_expired(xmls)
          urls = xmls.map{|s| s.listing_details.listing_url}
          Listing.idealpropertiesgroup.where.not(origin_url: urls).update_all status: 1
        end

        def setup
          xmls = nokogiri_xml.xpath('//Listing')
          xmls = xmls.map{|xml|
            obj = xml.to_hashie
            obj.flag = xml['type'] == 'sale' ? 0 : 1
            obj
          }
          xmls.uniq!{|s| s.listing_details.listing_url}
          set_expired xmls
          xmls.each do |xml|
            obj = retrieve_listing_object_from_db(xml)
            if xml.basic_details.try(:property_type) == 'Manufactured'
              obj.update_columns status: 33 unless obj.new_record?
              next
            end
            obj.url ||= xml.listing_details.listing_url
            # set listing enable
            obj.status = 0
            #res = spider.get obj.url
            #if res.code =~ /^4/
            #Listing.where(origin_url: obj.url).update_all status: 1
            #next
            #elsif res.code == '200'
            #doc = Nokogiri::HTML res.body
            #if doc.css('title').text.strip == 'Listing no longer available'
            #Listing.where(origin_url: obj.url).update_all status: 1
            #next
            #end
            #end
            #if !obj.new_record? && obj.created_at < Time.now - 2.day
            #attrs = {}
            #attrs[:status] = 0 if obj.expired?
            #if obj.raw_neighborhood.blank?
            #attrs[:raw_neighborhood] = xml.neighborhood.name
            #attrs[:raw_neighborhood] = attrs[:raw_neighborhood].split(/\-|\/|\(|\&/).first.strip  if attrs[:raw_neighborhood]
            #end
            #obj.update_columns(attrs) if attrs.present?
            #next
            #end
            # next if !obj.new_record? && obj.created_at > (Time.now - 1.day)
            obj.flag = xml.flag
            ## Location
            location = xml.location
            obj.street_address, obj.title = location.street_address, location.street_address
            obj.is_full_address = true
            obj.unit = location.unit_number
            obj.lat  = location.lat if location.lat
            obj.lng  = location.long if location.long
            obj.city_name = location.city
            obj.city_name = nil if obj.city_name == obj.neighborhood_name
            obj.state_name = location.state
            obj.zipcode = location["zip"] if (location["zip"] || '').strip.match(/\A\d{5}\Z/)
            obj.neighborhood_name = xml.neighborhood.try(:name) || xml.neighborhood
            obj.neighborhood_name = obj.neighborhood_name.split(/\-|\/|\(|\&/).try(:first) if obj.neighborhood_name
            ## location end
            ## listing detail
            detail =  xml.listing_details.merge xml.basic_details
            obj.price = detail.price.to_i
            obj.beds = detail.bedrooms
            obj.baths = detail.bathrooms
            obj.sq_ft = detail.square_feet
            obj.description = detail.description
            obj.listing_type = detail.property_type
            # listing detail end
            obj.amenities = xml.rich_details.keys
            # check listing is fee?
            check_is_fee obj, xml
            ## agent
            agent_xml = xml.agents.try(:agent) || xml.agent
            agent_xml = agent_xml[0] if Array === agent_xml
            broker = get_broker xml
            agent = get_agent agent_xml, broker
            obj.agent = agent
            obj.broker = broker
            obj.broker_name = broker.name
            obj.contact_name, obj.contact_tel = agent.name, agent.tel
            ## check price and beds
            if obj.beds.to_f == 0 && obj.price.to_i > 5000
              if obj.new_record?
                next
              else
                obj.update_columns status: 34
              end
            end

            if obj.save
              get_open_houses xml, obj
              if xml.pictures.present?
                if Array === xml.pictures.picture
                  images = xml.pictures.picture
                else
                  images = [xml.pictures.picture]
                end
                images.each do |pic|
                  ListingImage.where(origin_url: pic['picture_url'], listing_id: obj.id).first_or_create unless pic['picture_url'] =~ /default-photo/
                end if images.present?
              end
            end
          end
        end

        def retrieve_listing_object_from_db(listing)
          url = ListingUrl.where(url: listing.listing_details.listing_url).first
          if url
            url.listing
          else
            Listing.new
          end
        end

        def check_is_fee(listing, xml)
          if xml.to_s =~ /no\-fee|no\s+fee/i
            listing[:no_fee] = true
          else
            listing[:no_fee] = false
          end
        end
      end
    end
  end
end
