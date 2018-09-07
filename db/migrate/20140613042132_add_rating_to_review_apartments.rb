class AddRatingToReviewApartments < ActiveRecord::Migration
  def change
    add_column :review_apartments, :convenience, :integer, limit: 1
    add_column :review_apartments, :living, :integer, limit: 1
    add_column :review_apartments, :safety, :integer, limit: 1
  end
end
