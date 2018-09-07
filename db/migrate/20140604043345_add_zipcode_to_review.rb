class AddZipcodeToReview < ActiveRecord::Migration
  def change
    add_column :reviews, :zipcode, :string, limit: 10
  end
end
