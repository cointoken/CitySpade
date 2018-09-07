class AddGuarantorToListings < ActiveRecord::Migration
  def change
    add_column :listings, :guarantor, :boolean, default: false
  end
end
