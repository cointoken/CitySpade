class AddLatlngToPoliticalAreas < ActiveRecord::Migration
  def change
    add_column :political_areas, :lat, :float
    add_column :political_areas, :lng, :float
  end
end
