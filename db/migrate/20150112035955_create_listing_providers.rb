class CreateListingProviders < ActiveRecord::Migration
  def change
    create_table :listing_providers do |t|
      t.references :listing, index: true
      t.integer :provider_id, index: true
      t.string :client_name, limit: 20

      t.timestamps
    end
  end
end
