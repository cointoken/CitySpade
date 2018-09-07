class AddUnitToCheckinBuildings < ActiveRecord::Migration
  def change
    add_column :checkin_buildings, :unit, :string, null: false
  end
end
