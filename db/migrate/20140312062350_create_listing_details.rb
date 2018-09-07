class CreateListingDetails < ActiveRecord::Migration
  def change
    create_table :listing_details do |t|
      t.references :listing, index: true
      t.text :description

      t.timestamps
    end
  end
end
