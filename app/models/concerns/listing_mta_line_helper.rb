module ListingMtaLineHelper
  def ll
    @ll ||= Geokit::LatLng.new self.lat, self.lng
  end

  def cal_distance(key = nil)
    #destins = "#{self.lat},#{self.lng}" 
    #origins = "#{self.listing.lat},#{self.listing.lng}"
    #dms  = MapsServices::DistanceMatrix.new origins: origins, destinations: destins, units: 'imperial', key: key, mode: 'walking'
    #duration = dms.durations[0][0]
    #distance = dms.distances[0][0]
    dist = self.listing.ll.distance_to ll
    dist_m = dist * MILE_KM_TRANSLATE * 1000
    if dist > 0.1
      dist_text = "#{dist.round(1)} mi"
    else
      dist_text = "#{(dist * 1000).to_i} ft"
    end
    self.distance = dist_m.to_i
    self.distance_text = dist_text
    self.save
    #if duration.blank?
      #if (self.lat - self.listing.lat).abs < 0.01 && (self.lng - self.listing.lng).abs < 0.01
    #self.duration, self.duration_text = 1, '1 min'#duration['value'], duration['text']
    #self.distance, self.distance_text = 1, '1 ft'#distance['value'], distance['text']
    #self.save
      #end
    #else
    #self.duration, self.duration_text = duration['value'], duration['text']
    #self.distance, self.distance_text = distance['value'], distance['text']
    #end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def cal_distances(opt={})
      unscoped.where('listing_mta_lines.distance is null').limit(opt[:limit]).order('listing_mta_lines.id desc').each_with_index do |line, index|
        line.cal_distance(opt[:key] || (Settings.google_maps.server_keys[index % Settings.google_maps.server_keys.size]))
      end
    end
  end
end
