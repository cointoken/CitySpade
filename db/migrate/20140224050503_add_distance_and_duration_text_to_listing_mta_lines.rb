class AddDistanceAndDurationTextToListingMtaLines < ActiveRecord::Migration
  def change
    add_column :listing_mta_lines, :distance_text, :string, limit: 20
    add_column :listing_mta_lines, :duration_text, :string, limit: 20
  end
end
