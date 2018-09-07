class RenameColumnToListings < ActiveRecord::Migration
  def change
    rename_column :listings, :type_name, :listing_type_id
    change_column :listings, :listing_type_id, :integer
  end
end
