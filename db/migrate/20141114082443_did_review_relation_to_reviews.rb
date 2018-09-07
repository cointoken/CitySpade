class DidReviewRelationToReviews < ActiveRecord::Migration
  def change
    Review.all.each{|s| s.set_venue_info}
  end
end
