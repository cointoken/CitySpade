class CreateBuildingMtaLines < ActiveRecord::Migration
  def change
    create_table :building_mta_lines do |t|
      t.references :building, index: true
      t.references :mta_info_line, index: true
      t.references :building_place, index: true
      t.string :mta_info_type, limit: 10
      t.float :distance
      t.float :duration
      t.string :duration
      t.references :mta_info_st

      t.timestamps
    end
  end
end
