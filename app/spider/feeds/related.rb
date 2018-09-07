module Spider
  module Feeds
    class Related < Spider::Feeds::Base
      class	<< self
        @@brokers = {}
        def read_obj
          RestClient.get 'http://www.related.com/feeds/RelatedRentalsAvailabilitiesZillow.xml'
        end

        def nokogiri_xml
          @nokogiri_xml ||= Nokogiri::XML(read_obj)
        end

        def mls_name
          'Related'
        end

        def setup
          xmls = nokogiri_xml.xpath("//Listing")
          xmls = xmls.map{|xml| xml.to_hashie}
          listing_ids = []
          xmls.each do|xml|
            obj = retrive_listing_object_from_db(xml)
            open_houses = retrieve_open_houses xml, obj
            obj.status = 0
            #location
            location = xml.location

            broker = get_broker_info location.state

            obj.street_address = location.street_address
            obj.title =  location.street_address
            obj.unit = location.unit_number
            obj.unit = obj.unit.split('_').last if obj.unit
            obj.city_name = location.city # == 'New York' ? 'Manhattan' : location.city)
            obj.state_name = location.state
            obj.zipcode = location['zip']
            # if location.display_address == 'yes'
            obj.is_full_address = true
            # else
            #  obj.is_full_address = false
            # end
            #location end
            #listing details
            listing_details = xml.listing_details
            if listing_details.status =~ /rent/i || detail.price.to_i < 50000
              obj.flag = 1
            end
            if listing_details.price.to_i > 100000
              obj.flag ||= 0
            end
            obj.url = listing_details.listing_url
            obj.price = listing_details.price
            #listing details end
            #basic detail
            basic_details = xml.basic_details
            obj.listing_type = basic_details.property_type
            obj.description = basic_details.description
            obj.baths = basic_details.full_bathrooms
            obj.beds = basic_details.bedrooms
            #basic details end
            #rich detail
            features = xml.rich_details.try(:additional_features)
            if features.present?
              obj.amenities = features.split(',').map(&:strip)
            end
            #rich detail end
            #check listing fee?
            obj[:no_fee] = true
            #agent
            agent = xml.agent
            obj.contact_name = "#{agent.last_name}".strip
            obj.contact_tel  = (agent.office_line_number || agent.office_line_number).split(/[A-z]/)[0].gsub(/\D/, '')

            obj.broker ||= broker
            obj.open_houses ||= open_houses

            agent = Agent.get_from_realty_mx(xml.agent)
            obj.agent_id = agent.id
            #agent end
            obj.broker_name = "Related Companies"
            #pictures
            if obj.save
              listing_ids << obj.id
              agent.update_columns broker_id: broker.id if agent.broker_id.blank?
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
                ListingImage.where(origin_url: pic.picture_url, listing_id: obj.id).first_or_create
              end
            end
            #pictures end
          end
          Listing.related.where("id not in (#{listing_ids.join(',')})").each(&:set_expired)

        end

        def retrive_listing_object_from_db(listing)
          url = ListingUrl.where(url: listing.listing_details.listing_url).first
          if url
            url.listing
          else
            Listing.new
          end
        end

        def retrieve_open_houses xml, obj
          open_houses = []
          if xml.open_houses.present?
            xml.open_houses.open_house.each do |oh|
              open_date = Date.parse oh[:date]
              begin_time = Time.parse oh[:start_time]
              end_time = Time.parse oh[:end_time]
              open_houses << {open_date: open_date, begin_time: begin_time , end_time: end_time}
            end
          end
          open_houses
        end

        def get_broker_info(state_name)
          @@brokers[state_name] ||= begin
                                      opts = {name: "Related Companies",
                                              website: 'http://www.related.com',
                                              state: state_name
                                      }
                                      Broker.find_and_update_from_hash opts
                                    end
        end
      end
    end
  end
end
