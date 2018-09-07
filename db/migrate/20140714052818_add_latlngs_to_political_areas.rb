class AddLatlngsToPoliticalAreas < ActiveRecord::Migration
  def change
    add_column :political_areas, :ne_lat, :float
    add_column :political_areas, :ne_lng, :float
    add_column :political_areas, :sw_lat, :float
    add_column :political_areas, :sw_lng, :float
  end
end
