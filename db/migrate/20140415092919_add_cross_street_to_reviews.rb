class AddCrossStreetToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :cross_street, :string
  end
end
