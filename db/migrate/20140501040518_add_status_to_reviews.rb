class AddStatusToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :status, :boolean, default: true
  end
end
