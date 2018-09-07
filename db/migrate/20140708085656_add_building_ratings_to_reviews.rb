class AddBuildingRatingsToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :building, :integer, limit: 1
    add_column :reviews, :management, :integer, limit: 1
  end
end
