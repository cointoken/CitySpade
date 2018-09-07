class AddIsFullAddressToListings < ActiveRecord::Migration
  def change
    add_column :listings, :is_full_address, :boolean, default: true
  end
end
