class AddRatesToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :ground, :integer, limit: 1
    add_column :reviews, :quietness, :integer, limit: 1
    add_column :reviews, :safety, :integer, limit: 1
    add_column :reviews, :convenience, :integer, limit: 1
    add_column :reviews, :things_to_do, :integer, limit: 1
    add_column :reviews, :overall_quality, :integer, limit: 1
  end
end
