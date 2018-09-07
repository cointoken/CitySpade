class AddCompleteToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :complete, :boolean
  end
end
