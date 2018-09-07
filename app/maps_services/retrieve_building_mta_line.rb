module MapsServices
  class RetrieveBuildingMtaLine
    def self.setup(opt={})
      if opt.class.to_s == 'Building'
        buildings = [opt]
      elsif opt.is_a? Array
        buildings = opt
      else
        limit = opt[:limit] || 1000
        buildings = Building.limit(limit)
        buildings = buildings.where(political_area_id: PoliticalArea.all_city_sub_area_ids)
      end
      buildings.each_with_index do |building, index|
        sts = building.stations_near_by('subway_station')[0..10] + building.stations_near_by('bus_station')[0..10]
        new_lines_ids = []
        sts.each do |st|
          type = st.target.split('_').first
          line = building.building_mta_lines.find_or_create_by(mta_info_line: st.mta_info_line, target: type)
          line.update_attribute(:mta_info_st, st) if line.mta_info_st.blank?
          new_lines_ids << line.id
        end
        old_line_ids = building.building_mta_line_ids - new_lines_ids
        BuildingMtaLine.where(id: old_line_ids).delete_all
        #building.cal_place_flag([1,2])
        #building.update_column(:place_flag, building.place_flag + 3)
        #building.cal_distance_for_mta_line
      end
      BuildingMtaLine.cal_distances # TODO
    end
  end
end
