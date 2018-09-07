class ChangeBedsToListings < ActiveRecord::Migration
  def change
    change_column :listings, :beds, :float, default: 0
  end
end
