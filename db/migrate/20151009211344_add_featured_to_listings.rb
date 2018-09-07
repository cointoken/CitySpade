class AddFeaturedToListings < ActiveRecord::Migration

  def up
    add_column :listings, :featured, :boolean, default: false
  end
  
  def down
    remove_column :listings, :featured
  end

end
