class CreateListingImages < ActiveRecord::Migration
  def change
    create_table :listing_images do |t|
      t.references :listing, index: true
      t.string :url

      t.timestamps
    end
  end
end
