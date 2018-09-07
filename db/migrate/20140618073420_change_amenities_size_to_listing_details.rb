class ChangeAmenitiesSizeToListingDetails < ActiveRecord::Migration
  def change
    change_column :listing_details, :amenities, :string, limit: 2000
  end
end
