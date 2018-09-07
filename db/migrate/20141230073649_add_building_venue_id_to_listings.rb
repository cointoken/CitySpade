class AddBuildingVenueIdToListings < ActiveRecord::Migration
  def change
    add_column :listings, :building_venue_id, :integer
  end
end
