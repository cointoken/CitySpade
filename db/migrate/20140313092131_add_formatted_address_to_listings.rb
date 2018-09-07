class AddFormattedAddressToListings < ActiveRecord::Migration
  def change
    add_column :listings, :formatted_address, :string
  end
end
