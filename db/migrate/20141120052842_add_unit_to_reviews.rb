class AddUnitToReviews < ActiveRecord::Migration
  def change
    add_column :reviews, :unit, :string
  end
end
