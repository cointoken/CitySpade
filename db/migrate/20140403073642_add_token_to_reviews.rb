class AddTokenToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :token, :string
  end
end
