class ChangeReviewsLatlng < ActiveRecord::Migration
  def change
    change_column :reviews, :lat, :double
    change_column :reviews, :lng, :double
  end
end
