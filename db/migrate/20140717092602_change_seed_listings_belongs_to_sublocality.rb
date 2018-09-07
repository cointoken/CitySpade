class ChangeSeedListingsBelongsToSublocality < ActiveRecord::Migration
  def change
    # areas = PoliticalArea.where(target: "sublocality_level_1")
    # areas.each do |area|
    #   p area
    #   area = PoliticalArea.find_by_id(area.id)
    #   next unless area
    #   if area.parent.blank?
    #     area.destroy
    #     next
    #   end
    #   _area = area.parent.children.where(long_name: area.long_name, short_name: area.short_name, target: "sublocality").first
    #   area.reload
    #   if _area
    #     area.all_listings.each do |li|
    #       neighbor = li.political_area
    #       if neighbor != area
    #         sub_area = neighbor.real_area
    #         li.update_column(:political_area_id, sub_area.id)
    #       else
    #         li.update_column(:political_area_id, _area.id)
    #       end
    #     end
    #     area.destroy
    #   else
    #     area.update_column(:target, "sublocality")
    #   end
    # end
  end
end
