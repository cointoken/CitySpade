class AddTargetAndDistanceAndDurationTextToBuildingMtaLines < ActiveRecord::Migration
  def change
    add_column :building_mta_lines, :target, :string, limit: 20
    add_column :building_mta_lines, :distance_text, :string, limit: 20
    add_column :building_mta_lines, :duration_text, :string, limit: 20
  end
end
