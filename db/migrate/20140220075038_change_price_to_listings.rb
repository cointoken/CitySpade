class ChangePriceToListings < ActiveRecord::Migration
  def change
    change_column :listings, :price, :integer, default: 0
  end
end
