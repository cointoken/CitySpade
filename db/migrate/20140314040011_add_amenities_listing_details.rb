class AddAmenitiesListingDetails < ActiveRecord::Migration
  def change
    add_column :listing_details, :amenities, :string, limit: 500
  end
end
