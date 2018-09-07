class AddDefaultValueToListingsNoFee < ActiveRecord::Migration
  def change
    change_column :listings, :no_fee, :boolean, default: false
    Listing.enables.where(no_fee: nil).update_all no_fee: false
  end
end
