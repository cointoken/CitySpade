module Spider
  module Xml
    module Streeteasy
      def get_broker(xml)
        nil
      end
      def get_agent(xml={}, broker = nil)
        agent = (broker || get_broker(xml)).agents
          .where(name: xml.name, website: xml.url, email: xml.email, tel: xml.tel || xml.phone_numbers.cell.try(:remove, /\D/))
          .first_or_create#.update_attribute
        agent.update_attributes(origin_url: xml.photo) if xml.photo && xml.photo != agent.origin_url
        agent
      end
      def get_open_houses(xml={}, obj)
        if xml.open_houses.present?
          open_date = Date.parse xml.open_houses.open_house.starts_at.split(" ").first.strip
          begin_time = Time.parse xml.open_houses.open_house.starts_at.split(" ").last.strip
          end_time = Time.parse xml.open_houses.open_house.ends_at.split(" ").last.strip
          oh = {open_date: open_date, begin_time: begin_time, end_time: end_time}
          obj.open_houses.where({open_date: open_date}).first_or_initialize.update(oh)
        end
      end
      def set_expired(xmls)
        urls = xmls.map{|s| s['url']}
        site = self.to_s.split("::").last.downcase
        Listing.send(site).where.not(origin_url: urls).update_all status: 1
      end
      def setup
        xmls = nokogiri_xml.xpath('//property')
        set_expired xmls
        xmls = xmls.map{|xml|
          obj = xml.to_hashie
          obj.url = xml['url']
          obj.flag = xml['type'] == 'sale' ? 0 : 1
          obj.media = xml.css('media photo').map{|s| {url: s['url'].split('?itok=').first}}
          obj
        }
        xmls.each do |xml|
          obj = retrieve_listing_object_from_db(xml)
          if obj.nil?
            obj = Listing.new
          end
          if !obj.new_record? && obj.created_at < Time.now - 2.day
            attrs = {}
            attrs[:status] = 0 if obj.expired?
            if obj.raw_neighborhood.blank?
              attrs[:raw_neighborhood] = xml.location.neighborhood
              attrs[:raw_neighborhood] = attrs[:raw_neighborhood].split(/\-|\/|\(|\&/).first.strip  if attrs[:raw_neighborhood]
            end
            obj.update_columns(attrs) if attrs.present?
            next
          end
          if respond_to? :callback
            callback(xml)
          end
          # set listing enable
          obj.status = 0
          # next if !obj.new_record? && obj.created_at > (Time.now - 1.day)
          ## Location
          obj.url = xml.url
          location = xml.location
          obj.street_address, obj.title = location.address, location.address
          obj.is_full_address = true
          obj.unit = location.apartment
          obj.lat  = location.lat if location.lat
          obj.lng  = location.long if location.long
          obj.city_name = location.city
          obj.state_name = location.state
          obj.zipcode = location[:zipcode]
          obj.neighborhood_name = location.neighborhood.try(:name) || xml.neighborhood
          obj.city_name = 'New York' if obj.city_name == obj.neighborhood_name
          obj.neighborhood_name = obj.neighborhood_name.split(/\-|\/|\(|\&/).first if obj.neighborhood_name
          ## location end
          ## listing detail
          detail =  xml.details
          obj.flag = xml.flag
          obj.price = detail.price
          obj.beds = detail.bedrooms
          obj.baths = detail.bathrooms
          obj.sq_ft = detail.square_feet
          obj.description = detail.description
          obj.listing_type = detail.property_type
          # listing detail end
          if detail.amenities.present?
            obj.amenities = detail.amenities.keys
            if obj.amenities.include? 'other'
              obj.amenities.delete 'other'
              if detail.amenities.other.present?
                obj.amenities << detail.amenities.other.split(',').map(&:strip)
                obj.amenities.flatten!
              end
            end
          end
          # check listing is fee?
          check_is_fee obj, xml
          ## agent
          agent_xml = xml.agents.try(:agent) || xml.agents[0]
          agent_xml = agent_xml[0] if Array === agent_xml
          broker = get_broker agent_xml
          agent = get_agent agent_xml, broker
          obj.agent = agent
          obj.broker = broker
          obj.broker_name = broker.name
          obj.contact_name, obj.contact_tel = agent.name, agent.tel
          if obj.save
            get_open_houses xml, obj
            if xml.media.present?
              xml.media.each do |pic|
                ListingImage.where(origin_url: pic['url'], listing_id: obj.id).first_or_create unless pic['url'] =~ /default-photo/
              end
            end
          end
        end
      end

      def retrieve_listing_object_from_db(listing)
        url = ListingUrl.where(url: listing.url).first
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
