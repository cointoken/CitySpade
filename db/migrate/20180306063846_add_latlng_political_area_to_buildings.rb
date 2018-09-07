class AddLatlngPoliticalAreaToBuildings < ActiveRecord::Migration
  def change
    add_column :buildings, :lat, :float
    add_column :buildings, :lng, :float
    add_reference :buildings, :political_area, index: true
  end
end
