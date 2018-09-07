class ChangeAmenitiesToListingDetails < ActiveRecord::Migration
  def change
    change_column :listing_details, :amenities, :string, limit: 1000
    remove_column :listings, :deactivate
  end
end
