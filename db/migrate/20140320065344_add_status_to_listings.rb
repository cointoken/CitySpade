class AddStatusToListings < ActiveRecord::Migration
  def change
    add_column :listings, :status, :integer, limit: 1, index: true, default: 0
    Listing.enables.update_all(status: 0)
    Listing.where(deactivate: true).update_all(status: 1)
  end
end
