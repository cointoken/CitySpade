class AddDurationAndDistanceToListingPlaces < ActiveRecord::Migration
  def change
    add_column :listing_places, :distance, :integer
    add_column :listing_places, :duration, :integer
  end
end
