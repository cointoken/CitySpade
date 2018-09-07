class RenameIsFeeToNoFeeToListings < ActiveRecord::Migration
  def change
    rename_column :listings, :is_fee, :no_fee
  end
end
