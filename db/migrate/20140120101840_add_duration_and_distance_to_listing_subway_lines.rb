class AddDurationAndDistanceToListingSubwayLines < ActiveRecord::Migration
  def change
    add_column :listing_subway_lines, :distance, :integer
    add_column :listing_subway_lines, :duration, :integer
  end
end
