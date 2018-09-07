module BuildingMtaLineHelper
  def ll
    @ll ||= Geokit::LatLng.new self.lat, self.lng
  end

  def cal_distance(key = nil)
    dist = self.building.ll.distance_to ll
    dist_m = dist * MILE_KM_TRANSLATE * 1000
    if dist > 0.1
      dist_text = "#{dist.round(1)} mi"
    else
      dist_text = "#{(dist * 1000).to_i} ft"
    end
    self.distance = dist_m.to_i
    self.distance_text = dist_text
    self.save
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def cal_distances(opt={})
      unscoped.where('building_mta_lines.distance is null').limit(opt[:limit]).order('building_mta_lines.id desc').each_with_index do |line, index|
        line.cal_distance(opt[:key] || (Settings.google_maps.server_keys[index % Settings.google_maps.server_keys.size]))
      end
    end
  end
end
