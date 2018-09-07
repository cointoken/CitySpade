module Spider
  module Feeds
    class RoseAssociates < Spider::Feeds::Base
      class << self
        def urls
          ['http://adkast.messagekast.com/adkast/feed/cityspade.com/?id=fnjqlcsh']
        end
        def read_obj url
          RestClient.get url #'http://www.realtymx.com/demo/admin/tools/cityspade.xml'#File.read Rails.root.join('db', 'cityspade.xml')
          # File.read Rails.root.join('cityspadecom-2052.xml')
        end
        def nokogiri_xml url
          Nokogiri::XML(read_obj url)
        end

        def setup
          xmls = []
          urls.each do  |url|
            doc = nokogiri_xml url
            xmls << doc.xpath('//property').map(&:to_hashie)
          end
          xmls.flatten!
          ids = xmls.map{|s| s.details.provider_listingid}
          listing_ids = MlsInfo.where(name: mls_name).where("mls_id not in (#{ids.join(',')})").select(:listing_id).map(&:listing_id)
          Listing.where(id: listing_ids).update_all status: 1
          xmls.each do |xml|
            next if xml.listing_type != 'rental' || xml.status != 'for rent'
            broker = get_broker_from_xml(xml.site)
            agent  = get_agent_from_xml(xml.agent, broker)
            listing = retrieve_listing_oject_from_db(xml, broker.id, agent.id)
            unless listing.new_record?
              #next if listing.created_at < Time.now - 2.day
            end
            listing.flag = 1
            listing.no_fee = true
            location = xml.location
            listing.unit           = location.unit || location.unit_number
            listing.street_address = listing.title = location.street_address
            listing.city_name      = location.city_name
            listing.state_name     = location.state_code
           # listing.lng            = location.longitude
           # listing.lat            = location.latitude
            listing.zipcode        = location.zipcode
            listing.is_full_address = true

            details = xml.details
            listing.price   = details.price
            listing.beds    = details.num_bedrooms
            listing.baths   = details.num_bathrooms
            listing.sq_ft   = details.living_area_square_feet

            listing.contact_name = agent.name
            listing.contact_tel  = agent.tel

            listing.never_has_url = true

            listing.amenities   = get_amenites_from_xml(xml)
            listing.description = get_description_from_xml(xml, nil, agent.name)

            if listing.save
              # save to mls infos
              mls_info = MlsInfo.where(
                name: mls_name,
                mls_id: xml.details.provider_listingid,
                broker_id: broker.id,
                listing_id: listing.id
              ).first_or_create
              listing.update_columns mls_info_id: mls_info.id
              #images
              next unless listing.is_enable?
              next if xml.pictures.picture.blank?
              images = xml.pictures.picture[0..9]
              if xml.floorplan_layouts && xml.floorplan_layouts.floorplan_layout.try(:floorplan_layout_url).present?
                images.insert(1, {picture_url: xml.floorplan_layouts.floorplan_layout.floorplan_layout_url})
              end
              images = images[0..9]
              images.each do |img|
                ListingImage.where(listing_id: listing.id, origin_url: img[:picture_url]).first_or_create
              end
            end
          end
        end
        def get_broker_from_xml xml, state_name = 'NY'
          @brokers ||= {}
          @brokers[xml.site_name] ||= begin
                                        Broker.find_and_update_from_hash(
                                          # website: xml.site_url,
                                          name: get_broker_name(xml.site_name),
                                          state: state_name
                                        )
                                      end
        end

        def get_agent_from_xml xml, broker
          @agents ||= {}
          @agents["#{xml.agent_email}-#{xml.agent_name}"] ||= begin
                                                                broker.agents.where(
                                                                  email: xml.agent_email,
                                                                  name: xml.agent_name,
                                                                  tel: xml.agent_phone.try(:remove, /\D/)
                                                                ).first_or_create
                                                              end
        end

        def retrieve_listing_oject_from_db xml, broker_id, agent_id
          mlses = MlsInfo.where(name: mls_name).where(mls_id: xml.details.provider_listingid, broker_id: broker_id).where.not(listing_id: nil)
          if mlses.present?
            mlses.each do |mls|
              listing = mls.listing
              if listing && listing.is_enable? && listing.agent_id == agent_id
                return listing
              end
            end
          end
          attrs_hash = {no_fee: true, flag: 1, broker_id: broker_id, agent_id: agent_id}
          attrs_hash[:unit] = xml.location.try(:unit)
          attrs_hash[:street_address] = attrs_hash[:title] = xml.location.try(:street_address)
          attrs_hash[:price] = xml.details.try(:price).to_i
          attrs_hash[:beds] = xml.details.try(:beds)
          attrs_hash[:baths] = xml.details.try(:baths)
          valid_query = attrs_hash.slice(:unit, :title, :beds, :baths, :broker_id)
          valid_query[:price] = (attrs_hash[:price].to_i - 400)..(attrs_hash[:price] + 300) if valid_query[:unit].blank?
          valid_query[:origin_url] = nil
          Listing.where(valid_query).last || Listing.new(attrs_hash)
        end

        def get_amenites_from_xml(xml, arrs = [])
          xml.each do |key, value|
            if String === value
              if key.include? ('has_')
                arrs << key.sub(/^has_/, '').titleize
              end
            elsif value != nil
              get_amenites_from_xml(value, arrs)
            end
          end
          arrs
        end

        def get_description_from_xml(xml, dsc_str = '', site_name = '')
          dsc_str ||= ''
          xml.each do |key, value|
            if String === value
              if ['description', 'comment'].any?{|desc| key.include?(desc)}
                dsc_str << key.titleize << "\n" if ['description', 'comment'].any?{|k| k == key}
                dsc_str << value << "\n"
              end
            elsif value != nil
              get_description_from_xml(value, dsc_str)
            end
          end
          dsc_str
        end

        def get_broker_name(site_name)
          if site_name == 'StuyTown Apartments'
            site_name
          else
            'Rose Associates'
          end
        end
      end
    end
  end
end