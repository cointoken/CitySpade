class AddPlaceFlagToListings < ActiveRecord::Migration
  def change
    add_column :listings, :place_flag, :integer, limit: 1, default: 0
  end
end
