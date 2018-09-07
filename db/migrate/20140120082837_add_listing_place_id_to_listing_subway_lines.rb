class AddListingPlaceIdToListingSubwayLines < ActiveRecord::Migration
  def change
    add_reference :listing_subway_lines, :listing_place
  end
end
