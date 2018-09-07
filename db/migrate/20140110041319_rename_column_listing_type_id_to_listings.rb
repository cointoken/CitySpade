class RenameColumnListingTypeIdToListings < ActiveRecord::Migration
  def change
    change_column :listings, :listing_type_id, :string
    rename_column :listings, :listing_type_id, :listing_type
    add_column :listings, :flag, :integer, limit: 1
    add_index :listings, :listing_type
    add_index :listings, [:flag, :listing_type]
    #Listing.all.each do |list|
      ##list.listing_type = Settings.listing_types[list.type.to_i] if list.type
      #list.save
    #end
  end
end
