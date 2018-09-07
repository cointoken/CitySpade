class SeedFixFullAddressToListings < ActiveRecord::Migration
  def change
    listings = Listing.where(is_full_address: true)
    listings.each do |li|
      li.update_column(:is_full_address, false) if li.title =~ /\d+\s*(st|nd|th)\s/i
    end
  end
end
