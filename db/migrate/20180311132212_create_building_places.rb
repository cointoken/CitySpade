class CreateBuildingPlaces < ActiveRecord::Migration
  def change
    create_table :building_places do |t|
      t.string :name
      t.string :target
      t.float :lat
      t.float :lng
      t.integer :duration
      t.integer :distance
      t.references :building, index: true
      t.timestamps
    end
  end
end
