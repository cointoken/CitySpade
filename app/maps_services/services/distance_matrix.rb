module MapsServices
  class DistanceMatrix < Base
    def initialize(opts={}, url = nil)
      super
      @options[:mode] = 'walking'
    end
    def self.setup(listing = nil, places )
      origins     = "#{listing.lat},#{listing.lng}"
      if places
        places = [places] unless places.is_a? Array
      else
        places = listing.places
      end
      destinations= places.map{|pl| "#{pl.lat},#{pl.lng}"}.join('|')
      dms = new(origins: origins, destinations: destinations )
      durations = dms.durations[0]
      distances = dms.distances[0]
      return false unless distances
      places.each_with_index do |pl, i|
        pl.duration = durations[i]['value']
        pl.distance = distances[i]['value']
        pl.save
      end
    end
    def base_url
      'https://maps.googleapis.com/maps/api/distancematrix/json'
    end
    def rows
      json['rows']
    end
    def durations
      rows.map{|m| m['elements'].map{|j| j['duration']}}
    end
    def distances
      rows.map{|m| m['elements'].map{|j| j['distance']}}
    end
  end 
end
