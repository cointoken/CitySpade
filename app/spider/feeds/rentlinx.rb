module Spider
  module Feeds
    class Rentlinx < Spider::Feeds::Base
      class << self
        def provider?
          true
        end
        def client_name
          'Rentlinx'
        end
        def url
          'http://www.rentlinx.com/_database/cityspade_rentlinx.xml'
        end

        def nokogiri_xml
          Nokogiri::XML RestClient.get url
        end

        def setup
          docs = nokogiri_xml.children.first.children.first.children#.css('property')
          hashes = docs.map{|doc|
            hash = doc.to_hashie
            hash.amenities = doc.css('>Amenity').map{|s| 
              amen = s['AmenityName']
              if amen == 'Other'
                s.text.split(',').map(&:strip)
              else
                amen
              end
            }.reverse.uniq
            hash.property_id ||= doc['PropertyID'] || doc['propertyid']
            hash.url ||= doc['PropertyURL'] || doc["propertyurl"]
            hash.unit = doc.css('Unit').map{|s|
              h = s.to_hashie
              h.unit_id = s['UnitID']
              #h.name = s.name.sub(/unit/i, '').strip
              if h.name.downcase.include?("unit ") && h.name.downcase.split('unit ').size == 2
                h.name  = h.name.downcase.split(' ').last
              elsif !(!h.name.include?(' ') && (h.name.size < 5 || h.name !~ /[a-z]/i))
                h.name = nil
              end if h.name
              h.amenities = s.css('Amenity').map {|am|
                amen = am['AmenityName']
                if amen == 'Other'
                  am.text.split(',').map(&:strip)
                else
                  amen
                end
              }
              h.images = doc.css('UnitPhoto').map{|img| {origin_url: img['ImageUrl']}}
              h.url = (hash.url + "##{h.unit_id}").strip
              h
            }.uniq(&:unit_id)
            if !hash.address.nil?
              hash.address = hash.address.try(:split, '#').first.strip
            end
            hash.images = doc.css('PropertyPhoto').map{|img| {origin_url: img['ImageUrl']}} #doc.css('propertyphoto').map{|img| {origin_url: img['imageurl']}}
            hash
          }

          provider_ids = hashes.map{|s| s.unit.map{|unit| {provider_id: s.property_id, unit_id: unit.unit_id}}}.flatten
          Listing.enables.where(id: ListingProvider.where(client_name: client_name).where.not(unit_id: provider_ids.map{|s| s[:unit_id]}).select(:listing_id)).
            update_all status: 1, updated_at: Time.now
          hashes.each do |hash|
            update_listing hash
          end
          ## fix dup listing
          Listing.enables.where('origin_url like ?', '%rentlinx.com%').where.not(id: ListingProvider.where(client_name: client_name).
                                                                                 where(unit_id: provider_ids.map{|s| s[:unit_id]}).
                                                                                 pluck(:listing_id)).update_all status: 1, updated_at: Time.now
          BrokerLlsStatus.update_datas Date.today, 'Rentlinx'
        end

        def update_listing hash
          hash.unit.each do |unit|
            listing = ListingUrl.where(url: unit.url).first.try(:listing) || Listing.where(origin_url: unit.url).first
            if listing.blank?
              lp = ListingProvider.where(client_name: client_name).where(provider_id: hash.property_id, unit_id: unit.unit_id).first
              if lp && lp.listing
                listing = lp.listing
              else
                listing = Listing.rentals.new(origin_url: unit.url)
              end
            end
            listing.status = 0
            listing.url = unit.url
            listing.title = hash.address
            listing.unit = unit.name
            listing.price = unit.rent
            listing.beds = unit.bedrooms
            listing.baths = unit.full_baths.to_i + unit.half_baths.to_i * 0.5
            next if listing.beds.to_i < 0 || listing.baths.to_i < 0
            listing.amenities = (unit.amenities + hash.amenities).flatten.uniq
            listing.description = "#{unit.description} \n #{hash.description}"
            listing.state_name = hash.state
            listing.zipcode = hash['zip']
            listing.contact_tel = hash.phone_number.remove(/\D/)
            listing.contact_name = hash.company_name
            if hash.upgrade_status == 'free'
              #listing.no_fee = true
            end
            # IF <NoFee>1</NoFee>, set it as NO FEE 
            if hash.no_fee == '1'
              listing.no_fee = true 
            end
            #if ['Broker', 'Agent'].include? hash.account_type
            broker = Broker.find_and_update_from_hash name: hash.company_name, state: hash.state
            listing.broker_id = broker.id
            #if hash.account_type == 'Agent'
            agent = broker.agents.find_and_update_from_hash email: hash.email_address, tel: hash.phone_number.remove(/\D/)#, name: hash.marketing_name
            listing.agent_id = agent.id
            #end
            #end
            if listing.save
              (unit.images + hash.images).each do |img|
                ListingImage.where(listing_id: listing.id).where(img).first_or_create
              end
              ListingProvider.update_provider client_name: client_name, provider_id: hash.property_id, listing_id: listing.id, unit_id: unit.unit_id
            end
          end
        end
      end
    end
  end
end
