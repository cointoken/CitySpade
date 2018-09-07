class AddVenueIdToReviews < ActiveRecord::Migration
  def change
    add_reference :reviews, :venue, index: true
  end
end
