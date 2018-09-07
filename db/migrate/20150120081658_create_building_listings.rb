class CreateBuildingListings < ActiveRecord::Migration
  def change
    create_table :building_listings do |t|
      t.references :building, index: true
      t.references :listing,index: true

      t.timestamps
    end
  end
end
