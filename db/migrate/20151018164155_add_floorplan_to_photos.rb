class AddFloorplanToPhotos < ActiveRecord::Migration

  def up
    add_column :photos, :floorplan, :boolean, default: false
  end
  
  def down 
    remove_column :photos, :floorplan
  end

end
