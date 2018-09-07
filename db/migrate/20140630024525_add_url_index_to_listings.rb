class AddUrlIndexToListings < ActiveRecord::Migration
  def change
    add_index :listings, :origin_url
    add_index :listing_urls, :url
    add_index :listing_images, :origin_url
  end
end
