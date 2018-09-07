class AddFloorplanToListingImages < ActiveRecord::Migration
  def change
    add_column :listing_images, :floorplan, :boolean, default: false
  end
end
