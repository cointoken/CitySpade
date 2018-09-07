module MapsServices
  class Place < Base
    TYPES = Settings.try(:place_types) || %w{ subway_station  bus_station}
    def self.setup(opt={ lclass: Listing, limit: 1000})
      flag = opt[:flag] || true
      return if flag
      if opt.is_a?(Listing)
        listings = [opt]
      elsif opt.is_a? Array
        listings = opt
      else
        lclass = opt[:lclass] || Listing
        listings = lclass.no_places.limit(opt[:limit])
        listings = listings.where(political_area_id: PoliticalArea.all_city_sub_area_ids)
      end
      listings.each_with_index do |listing,index|
        key = Settings.google_maps.server_keys.first
        place = new(location: "#{listing.lat},#{listing.lng}", key: key)
        ActiveRecord::Base.transaction do
          TYPES.each do |type|
            place.send(type)[0..4].each do |pl|
              l = pl['geometry']['location']
              listing.places.find_or_create_by(name: pl['name'], lat: l['lat'], lng: l['lng'], target: type)
            end
          end
          listing.update_place_flag(1)
        end
        # listing.cal_distance_for_listing_places
        sleep(rand)
      end 
      # ListingPlace.cal_distances
    end

    def initialize(options = {})
      super
      @options[:radius] ||= 800
      @options[:key]    ||= Settings.google_maps.server_keys.sample
      @options[:rankby] ||= 'distance'
      @options.delete :radius if @options[:rankby] == 'distance'
      @options[:types]  ||= 'subway_station'
      if @options[:pagetoken]
        @options = {pagetoken: @options[:next_page_token],sensor: false, key: @options[:key]}
      end
    end
    TYPES.each do |key|
      define_method key do
        options = @options.clone
        options[:types] = key
        eval("@#{key} ||= MapsServices::Place.new(options).json")
      end
    end

    def json(type = nil)
      if type
        @logger.info type
        self.send type
      else
        j = JSON.parse get
        while j['status'] != 'OK' 
          raise 'over limit' unless allow?
          if j['status'] == 'ZERO_RESULTS'
            if @options[:radius] && @options[:radius] < 3000
              @options[:radius] += 800
              @get = nil
              @logger.info @options
              @logger.info get_url
              j = JSON.parse get
            else
              return []
            end
            return []
          else
            return []
          end
        end
        j['results'].uniq{ |j| j['name'] }
      end
    end

    def base_url
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
    end

    def next_page?
      !!next_page_token
    end

    def next_page_token
      json['next_page_token']
    end
    def next_page(token)
      options[:pagetoken] = token
      MapsServices::Base.new(options,base_url).json
    end
  end
end
