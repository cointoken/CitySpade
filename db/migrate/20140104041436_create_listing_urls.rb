class CreateListingUrls < ActiveRecord::Migration
  def change
    create_table :listing_urls do |t|
      t.references :listing, index: true
      t.string :url

      t.timestamps
    end
  end
end
