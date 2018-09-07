class AddOriginUrlToListingImages < ActiveRecord::Migration
  def change
    add_column :listing_images, :origin_url, :string
  end
end
