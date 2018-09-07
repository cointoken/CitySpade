class AddAccountIdToListings < ActiveRecord::Migration
  def change
    add_reference :listings, :account, index: true
  end
end
