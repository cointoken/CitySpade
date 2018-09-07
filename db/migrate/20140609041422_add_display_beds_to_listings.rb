class AddDisplayBedsToListings < ActiveRecord::Migration
  def change
    add_column :listings, :display_beds, :integer, default: 0, limit: 1
  end
end
