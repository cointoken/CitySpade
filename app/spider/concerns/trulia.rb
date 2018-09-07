module Spider
  module Xml
    module Trulia
      # NESTIOLIST = ["AToZ", "Anchornyc", "BoldNewYork",
      #              "BrickAndMortar", "Cbreliable", "InHouseGroup","Compassrock",
      #              "DBaum", "Dorsa", "NYVirtualRealtyCorp","Chapin","DouglasElliman", "DwellResidential","RoyalLivingNYC",
      #              "ExitRealtyKingdom", "Fiddler", "Galleria", "JosephGiordano","HechtGroup","NelsonAybar",
      #              "Instratany", "Lucienperry", "IanShapolsky","UptownFlats","ModaRealty","WindsorMariners",
      #              "NewYorkHomes", "Newcastlenyc", "WorldWideHomes","NYSRealty","NyCasaGroup", "Siderow","KeyWorthyLLC",
      #              "OffsiteLeasing", "OneAndOnly", "DirectProperties","PhillpSalamon",
      #              "Pistilli", "ResNewYork", "FurnishedDwellings","WoodsAssociates","RosemarkGroup", "YucoManagement","Rudin",
      #              "SkyManagement", "Skylinedevelopers", "AJM","AviRealty","SkyRealEstate", "Spire",
      #              "Swythe", "UDR","Dermot",
      #              "GarfieldRealty","EmpireStateProperties","CitadelProperty","Olshan","FirstServiceResidential","TheCorner",
      #              "Winzonerealty", "KartenLowe","BohbotSteven","EXR","AJClarke","AltasRealty","AlchemyVentures","JackParker","TradeNYC","MetroPlus","Concept","RoomConnect","GPSRealty","Lalezarian", "Silverstein", "WaveRealEstate", "AbleRealty", "ThorEquities", "Albanese", "Simone", "Jameson", "DwellPost", "Citinest", "Azulay", "VillageAcquisition", "UrbanApartment", "Northwind", "Loftey", "Fenway", "RedSparrow", "CityView", "DeanJacob", "JeromeMeyer", "HudsonRealEstate", "IanKKatz", "IntPropFinder","BigSquare", "RGC","BetterLiving","DefiantRealty", "JRProperties","Parkstone","PrimeHome", "Nectar","ArdmoreWinthrop", "Gama","AAManagement","Westminster","Rosenyc","SpacesProperty","LuxuryChicago","Akelius","Estilo","Bedford","FiveStar","KellerWilliams","Fetner","Realtyka","Elanrealty","Buzzer","PerlGroup","HmrProperties","AllAmericanRltyMgt","DansarGroup","ClipperEquities","HomedaxRealestate","KellerWilliamsMidtown","MetropolitanRealty","JpAssociates","Horowitz","DwellChicago","CrumlishRealEstate","DevCoGroup","CarnegieHillProperties","TheMonterey","BohemiaRealty","RenegadeNY","AventanaRealEstate","ArmCapital","InHausLlc","ShorecrestTowers","PerryAssociates","OakTree","Waterton","Resis","GlaProperty","AptAmigo","JcaProperty","VoyeurRealEstate","NovoProperties","IndependentProp","AkeliusRealestate","WingateCompanies","TheRealEstate","SimplyBrooklyn","FifthForever","DrennenRealty","MQPropertyMgmt","LifestyleRealty","GioiaRealty","SpyRLT","IqRealtors","SolarManagement","BlantonTurner", "DJKResidential","GothamOrganization","BrennanRealty","CicadaInternational","ExcelsiorRealty","BuchbinderWarren","LoftsAndFlats","Tryax","Caprijetrealty","U2apartment","Hotspot","Promisereal","Glasserreal","Fetnerpropinc","Fountainreal","Pistillireal","Atkinson","Brookblocreal","Peterkinang","Thesuitliber","ListingMule","SJPModern","LaMatto","IstayNY","Pinnacle","UrbanRealEstate","Absolute","WorkLive","AdvantaService","Univreallc","LanReal","Marvereal","Omniman","Voronyc","Davidass","TheWilliams","ExtellMarketing","MontSky","BryanLRRealty","CityWideApts","UESMgmt","SFRent","Relocation","KARealty","Manmiareal","Myhomead","Triview","RYManagement","Kushner","Stonehenge","CityDigs","Dermoteast","Moinian","Azure","Extell","Lovefirstreal","Aveagency","Eliteconn","RealCollect"]

   # Deactivated Per Nestio
      #"GosenProperties", "Americarealtyky", "MaxwellCharlesRealEstate","MenaRealEstate",
      #"Maison", "LivWisely", "EliteNYHoldings", "BarnesInternational"

      def displayed_address
        NESTIOLIST.map do |feed|
          Spider::Feeds.const_get(feed)
        end
      end

      def hashie_to_listing_hash(hash, callback = {})
        listing = {}

        if hash[:location][:display_address] == "yes" && displayed_address.include?(self)
          listing[:listing_type] = hash.listing_type
          # if hash.listing_type.blank? || hash.listing_type.start_with?('rent')
          if hash.listing_type.blank? || hash.listing_type.try(:downcase).include?('rent')
            listing[:flag] = 1
          else
            listing[:flag] = 0
          end
          if hash.status.downcase.start_with? 'for'
            listing[:status] = 0
            listing[:flag] = 0 if hash.status.include?('sale')
          else
            listing[:status] = 1
          end
          location = hash.location
          listing[:unit] = location.unit_number
          listing[:street_address] = listing[:title] = location.street_address
          listing[:city_name] = location.city_name
          listing[:state_name] = location.state_code
          listing[:zipcode] = location.zipcode
          listing[:lat] = location.lat || location.latitude
          listing[:lng] = location.lng || location.longitude
          listing[:raw_neighborhood] = location.neighborhood_name
          if hash.landing_page && hash.landing_page.lp_url
            listing[:url] = hash.landing_page.lp_url
          end
          detail = hash.details
          listing[:price] = detail.price
          listing[:beds] = detail.num_bedrooms
          listing[:baths] = detail.num_full_bathrooms.to_i + detail.num_half_bathrooms.to_i * 0.5
          listing[:sq_ft] = detail.living_area_square_feet
          if detail.description
            listing[:description] = ActionView::Base.full_sanitizer.sanitize detail.description.gsub(/(\<br\s+\/\>)+/, "\n")
          end
          listing[:images] = []
          if hash.pictures.present?
            if Array === hash.pictures.picture#.each do ||
              images = hash.pictures.picture
            else
              images = [hash.pictures.picture]
            end
            images.each do |img|
              listing[:images] << {origin_url: img.picture_url}
            end
          end
          if hash.floorplan_layouts && hash.floorplan_layouts.floorplan_layout.present?
            if Array === hash.floorplan_layouts.floorplan_layout
              layout_urls = hash.floorplan_layouts.floorplan_layout
            else
              layout_urls = [hash.floorplan_layouts.floorplan_layout]
            end
            i = 0
            i += 1 unless listing[:images].blank?
            layout_urls.each do |layout|
              listing[:images].insert i, {origin_url: layout.floorplan_layout_url, floorplan: true}
              i += 1
            end
          end
          ## open houses
          open_houses = []
          if hash.open_homes.present?
            if hash.open_homes.class == XmlHash
              open_homes = []
              open_homes.push(hash.open_homes)
              hash.open_homes = open_homes
            end

            hash.open_homes.each do |oh|
              if oh.open_home.present?
                if oh.open_home.class == XmlHash
                  open_home = []
                  open_home.push(oh.open_home)
                  oh.open_home = open_home
                end
                oh.open_home.each do |o|
                  open_house = {}
                  open_house[:open_date] = Date.parse o.date
                  open_house[:begin_time] = Time.parse(o.start_time)
                  open_house[:end_time] = Time.parse(o.end_time)
                  open_houses << open_house
                end
              end
            end
          end
          listing[:open_houses] = open_houses

          ## broker
          broker = {}
          broker[:name] = hash.site.site_name
          broker[:website] = hash.site.site_url
          broker[:state] = location.state_code
          listing[:broker] = broker
          ## agent
          agent = {}
          agent[:name] = hash.agent.agent_name
          agent[:email] = hash.agent.agent_email
          agent[:tel] = hash.agent.agent_phone.remove(/\D/) if hash.agent.agent_phone
          agent[:origin_url] = hash.agent.agent_picture

          listing[:broker] = broker
          listing[:agent] = agent
          listing[:amenities] = []
          (hash[:detailed_characteristics] || []).each do |key, value|
            if String === value && value == 'yes'
              listing[:amenities] << key.split('has').last.titleize
            elsif Hash === value
              value.each do |k, v|
                if String === v
                  if v == 'yes'
                    listing[:amenities] << k.split('has').last.strip.titleize
                  elsif v != 'no' && key.include?('amenity')
                    listing[:amenities] << v.titleize
                  end
                elsif Array === v && key.include?('amenities')
                  listing[:amenities] += v.map(&:titleize)
                end
              end
            end
          end
          if hash.rental_terms && Hash === hash.rental_terms
            if hash.rental_terms.pets
              hash.rental_terms.pets.each do |key, value|
                if String === value && value == 'yes'
                  listing[:amenities] << key.split('has').last.titleize
                end
              end
            end
            if hash.rental_terms.rental_broker_fee && hash.rental_terms.rental_broker_fee =~ /no/i
              listing[:no_fee] = true
            end
          end

          if self == Spider::Feeds::Urbanrealtynyc
            listing[:no_fee] ? listing[:is_full_address] = true : listing[:status] = 1
          end

          listing[:amenities] = listing[:amenities].map(&:strip)
          if callback.present?
            callback.each do |key, value|
              if Proc === value
                listing[key] = value.call(listing[key])
              else
                listing[key] = value
              end
            end
          end
          listing[:provider_id] = hash.details.provider_listingid

          #####   Deal with Display Address   #####
          listing[:is_full_address] = false if hash[:location][:display_address] == "no" && self != Spider::Feeds::Benjaminrg
          ##### ##### ##### ##### ##### ##### #####
        end

        listing

      end

      def ids_and_urls xmls
        hash = {urls: [], ids: []}
        xmls.each{|s| hash[:urls] << s.site.site_url; hash[:ids] << s.details.provider_listingid}
        hash
      end

      def provider_id xml
        s.details.provider_listingid
      end

      def set_listing_provider(xml, client_name)
        provider_id = xml.delete :provider_id
        if provider_id
          ListingProvider.where(client_name: client_name, provider_id: provider_id).first_or_create
        end
      end

      def expired_listing_from_provider(ids, client_name)
        Listing.where(id: ListingProvider.where(client_name: client_name).where.not(provider_id: ids).pluck(:listing_id)).update_all status: 1
      end

      def get_listing_from_provider(xml, client_name)
        provider_id = xml[:provider_id]
        if provider_id
          provider = ListingProvider.where(client_name: client_name, provider_id: provider_id).first
          if provider
            return provider.listing || Listing.new
          end
        end
        Listing.new
      end

      def set_listing(xml, update_flag = true)
        return if xml.blank?
        listing = get_listing_from_provider xml, client_name
        unless listing.new_record?
          return if listing.created_at < Time.now - 2.day && update_flag
        end
        provider = set_listing_provider(xml, client_name)#.try(:id)
        listing.listing_provider_id = provider.try :id
        return if xml[:broker].blank? || xml[:agent].blank?
        broker = get_broker xml.delete :broker
        agent = get_agent xml.delete(:agent), broker
        xml_open_houses = xml.delete(:open_houses)
        images = xml.delete :images
        xml[:agent_id], xml[:broker_id] = agent.id, broker.id
        xml[:broker_name] = broker.try(:name) || client_name
        xml[:contact_name] = agent.name || broker.name
        xml[:contact_tel] = agent.tel || broker.tel || default_tel
        xml[:contact_tel].remove(/\D/) if xml[:contact_tel]
        if listing.update_attributes xml
          provider.update_columns listing_id: listing.id if provider
          xml_open_houses.map{ |xoh| xoh[:listing_id] = listing.id }
          get_open_houses xml_open_houses
          images.each do |img|
            listing.images.where(img).first_or_create
          end
        end
      end

      def default_tel
        nil
      end
      def get_broker(broker_xml)
        Broker.find_and_update_from_hash broker_xml
      end

      def get_agent(agent_xml, broker)
        broker.agents.find_and_update_from_hash(agent_xml.to_hash)
      end

      def get_open_houses(open_houses_xml)
        open_houses_xml.each {|oh| OpenHouse.where(oh.slice(*[:open_date, :listing_id])).first_or_initialize.update(oh)}
      end

      def extend_trulia?
        true
      end
    end
  end
end
