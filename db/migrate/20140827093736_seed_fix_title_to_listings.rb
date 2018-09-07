class SeedFixTitleToListings < ActiveRecord::Migration
  def change
    Listing.fix_is_full_address_or_title
  end
end
