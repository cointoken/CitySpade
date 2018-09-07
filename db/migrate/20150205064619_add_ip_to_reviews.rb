class AddIpToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :ip, :string, limit: 16
  end
end
