module Spider
  module Feeds
    class Rentrose < Spider::Feeds::Base
      class << self
        def provider?
          true
        end
        def client_name
          'Rentrose'
        end
        def url
          'http://www.rentrose.com/feeds.aspx?Post=streeteasy'
        end

        def nokogiri_xml
          Nokogiri::XML RestClient.get url
        end

        def setup
          docs = nokogiri_xml.css('property')
          hashes = docs.map{|doc|
            hash = doc.to_hashie
            hash.flag = doc['type'] == 'sale' ? 0 : 1
            hash.status = doc['status'] == 'active' ? 0 : 1
            hash.property_id = doc['id'].remove(/\D/)
            hash.images = doc.css('photo').map{|img| {origin_url: img['url']}}
            #hash.amenities = doc.css('Amenity').map{|s| s['AmenityName'] || s['amenityname']}.reverse.uniq
            #hash.property_id ||= doc['PropertyID'] || doc['propertyid']
            #hash.url ||= doc['PropertyURL'] || doc["propertyurl"]
            #hash.address = hash.address.split('#').first.strip
            #hash.images = doc.css('PropertyPhoto').map{|img| {origin_url: img['ImageUrl']}} #doc.css('propertyphoto').map{|img| {origin_url: img['imageurl']}}
            hash
          }
          hashes.each do |hash|
            update_listing hash
          end
        end

        def set_listing_provider(id)
          ListingProvider.where(client_name: client_name, provider_id: id).first_or_create
        end

        def get_listing_from_provider(id)
          provider = ListingProvider.where(client_name: client_name, provider_id: id).first
          if provider
            return provider.listing || Listing.new
          end
          Listing.new
        end
        def update_listing hash
          provider_id = hash.delete :property_id
          return unless provider_id
          listing = get_listing_from_provider provider_id
          provider = set_listing_provider(provider_id)
          listing.listing_provider_id = provider.try :id
          listing.flag = hash.flag
          listing.status = hash.status
          listing.no_fee = true if listing.is_rental?
          ## location
          location                  = hash.location
          listing.title             = location.address
          listing.unit              = location.apartment
          listing.state_name        = location.state
          #listing.raw_neighborhood  = location.neighborhood
          listing.zipcode = location.zipcode

          ## details
          detail = hash.details
          listing.price = detail.price
          listing.detail_hash = {maintenance: detail.maintenance}
          listing.beds        = detail.bedrooms
          listing.baths       = detail.bathrooms
          listing.sq_ft       = detail.square_feet
          listing.description = detail.description
          listing.amenities   = detail.amenities.values.map{|s| s.split(',').map(&:strip)}.flatten if detail.amenities

          ## agent
          agent_xml = hash.agents.agent
          if Hash === agent_xml
            agent = Agent.find_and_update_from_hash name: agent_xml.name, email: agent_xml.email, tel: agent_xml.phone_numbers.main.try(:remove, /\D/)
            listing.agent = agent
            listing.contact_name, listing.contact_tel = agent.name, agent.tel
          else
            return
          end
          ## images
          images = hash.delete :images
          if listing.save
          provider.update_columns listing_id: listing.id if provider
            images.each do |img|
              listing.images.where(img).first_or_create
            end
          end
          #hash.unit = hash.unit.first if Array === hash.unit
          #return unless Hash === hash.unit
          #base_hash = {url: hash[:url], price: hash.unit.rent || hash.minrent, beds: hash.unit.bedrooms, title: hash.address, unit: hash.unit.name, flag: 1}
          #listing = Listing.get_listing_from_spider(base_hash) || Listing.new(flag: 1)
          #listing.title = hash.address
          #listing.url = hash[:url]
          #listing.price = hash.unit.rent || hash.min_rent
          #listing.beds = hash.unit.bedrooms
          #listing.baths = hash.unit.full_baths.to_i + hash.unit.half_baths.to_i * 0.5
          #listing.amenities = hash.amenities
          #listing.description = hash.description
          #listing.state_name = hash.state
          #listing.zipcode = hash['zip']
          #listing.contact_tel = hash.phone_number.remove(/\D/)
          #listing.contact_name = hash.company_name
          #if hash.upgrade_status == 'free'
          ##listing.no_fee = true
          #end
          #if ['Broker', 'Agent'].include? hash.account_type
          #broker = Broker.find_and_update_from_hash name: hash.company_name, state: hash.state
          #listing.broker_id = broker.id
          #if hash.account_type == 'Agent'
          #agent = broker.agents.find_and_update_from_hash email: hash.email_address, tel: hash.phone_number.remove(/\D/)
          #listing.agent_id = agent.id
          #end
          #end
          #if listing.save
          #hash.images.each do |img|
          #ListingImage.where(listing_id: listing.id).where(img).first_or_create
          #end
          #ListingProvider.update_provider client_name: client_name, provider_id: hash.property_id, listing_id: listing.id
          #end
        end
      end
    end
  end
end
