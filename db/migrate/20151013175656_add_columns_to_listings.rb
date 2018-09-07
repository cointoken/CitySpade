class AddColumnsToListings < ActiveRecord::Migration
  
  def up
    add_column :listings, :featured_at, :datetime
    add_column :listings, :featured_until, :datetime
  end
  
  def down
    remove_column :listings, :featured_at, :datetime
    remove_column :listings, :featured_until, :datetime
  end

end
