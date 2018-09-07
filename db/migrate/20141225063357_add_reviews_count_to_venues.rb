class AddReviewsCountToVenues < ActiveRecord::Migration
  def change
    unless Venue.column_names.include? "reviews_count"
      add_column :venues, :reviews_count, :integer, default: 1
      Venue.all.each do |venue|
        reviews_count = venue.reviews.count
        venue.update_column(:reviews_count, reviews_count)
      end
    end
  end
end
