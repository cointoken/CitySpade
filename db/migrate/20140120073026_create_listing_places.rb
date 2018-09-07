class CreateListingPlaces < ActiveRecord::Migration
  def change
    create_table :listing_places do |t|
      t.string :name
      t.string :target
      t.float :lat
      t.float :lng
      t.references :listing, index: true

      t.timestamps
    end
  end
end
