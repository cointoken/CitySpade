class AddHotToReview < ActiveRecord::Migration
  def change
    add_column :reviews, :hot, :integer
    add_index :reviews, :hot
  end
end
