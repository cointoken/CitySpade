class AddTagSizeToListingImages < ActiveRecord::Migration
  def change
    add_column :listing_images, :tag, :string, limit: 20
    add_column :listing_images, :size, :string, limit: 20
  end
end
