class AddFormattedAddressIndexToListings < ActiveRecord::Migration
  def change
    add_index :listings, :formatted_address
  end
end
