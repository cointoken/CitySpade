class AddZipcodeIndexToListings < ActiveRecord::Migration
  def change
    add_index :listings, :zipcode
  end
end
