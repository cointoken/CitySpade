class RenamePoliticalAreaIdToZipcodeAreas < ActiveRecord::Migration
  def change
    rename_column :zipcode_areas, :political_area_id, :political_area_name
    change_column :zipcode_areas, :political_area_name, :string
  end
end
