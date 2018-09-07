module MapsServices
  class CalTransportDistance
    def self.setup(opt={limit: 200}, cal_score = true)
      listings = []
      area_ids     = PoliticalArea.all_city_sub_area_ids #nyc.sub_areas(include_self: true).map(&:id) + philadelphia.sub_areas(include_self: true).map(&:id)
      if opt.is_a? Array
        listings = opt
      elsif opt.class.to_s == 'Listing'
        listings = [opt]  if area_ids.include? opt.political_area_id
      else
        #nyc = PoliticalArea.nyc#default_area
        #philadelphia = PoliticalArea.philadelphia

        listings = Listing.no_cal_transport_distances.where(%Q{
                                              political_area_id in (#{area_ids.join(',')})
                                                            }).limit(opt[:limit]).where(opt[:query])
        listings = listings.order('listings.flag desc, listings.id desc')
        # listings = listings.where(political_area_id: PoliticalArea.nyc.sub_ids)
        # modes for: driving walking bicycling transit
      end
      unless opt.is_a? Hash
        opt = {}
      end
      modes = ['transit', 'walking']
      listings.each_with_index do |listing, listing_i|
        # ActiveRecord::Base.transaction do
        modes.each do |mode|
          area = listing.political_area
          if area && area.borough_transport_places.present?
            transport_places = area.borough_transport_places
            destinations = transport_places.map{ |t| t.formatted_address }
            destinations.each_with_index do |destination, index|
              next if TransportDistance.where(listing: listing, transport_place: transport_places[index], mode: mode).first
              options = {origin: "#{listing.lat},#{listing.lng}", destination: destination, mode: mode, key: opt[:key]}
              if mode == 'transit'
                time = Time.now
                options[:departure_time] = (time.end_of_week + 2.day + 12.hour).to_i
              end
              distance     = MapsServices::Direction.new options
              # Rails.logger.info distance.get_url
              unless distance.distance
                options.delete :departure_time
                mode1 = 'driving'
                options[:mode] = mode1
                distance     = MapsServices::Direction.new options
              end
              next if distance.status == 'ZERO_RESULTS'
              unless distance.allow?
                raise "over get #{distance.get_url}"
              end
              if distance.distance && distance.duration
                transport_distance = TransportDistance.where(listing: listing, transport_place: transport_places[index], mode: mode).first_or_initialize
                transport_distance.distance = distance.distance['value']
                transport_distance.duration = distance.duration['value']
                transport_distance.save
              else
                p distance.json
                p distance.get_url
                raise 'no data'
              end
            end
          end
        end
        listing.update_place_flag(4)
        # end
      end
      if cal_score
        if opt.is_a? Hash
          MapsServices::TransportScore.setup query: 'listings.score_transport is null'
        else
          MapsServices::TransportScore.setup opt
        end
        #MapsServices::TransportScore.manhattan query: 'listings.score_transport is null'
        #MapsServices::TransportScore.brooklyn query: 'listings.score_transport is null'
        #MapsServices::TransportScore.queens query: 'listings.score_transport is null'
        #MapsServices::TransportScore.philadelphia query: 'listings.score_transport is null'
      end
    end
  end
end
