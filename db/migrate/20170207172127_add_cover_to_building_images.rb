class AddCoverToBuildingImages < ActiveRecord::Migration
  def change
    add_column :building_images, :cover, :boolean, default: false
  end
end
