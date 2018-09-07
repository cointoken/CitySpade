class AddSizesToListingImages < ActiveRecord::Migration
  def change
    add_column :listing_images, :sizes, :string
  end
end
