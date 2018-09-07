class AddAccountIdToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :account_id, :integer
  end
end
