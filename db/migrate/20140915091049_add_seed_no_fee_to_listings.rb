class AddSeedNoFeeToListings < ActiveRecord::Migration
  def change
    Listing.enables.each do |l|
      if l.amenities.to_s =~ /no\-fee|no\s+fee/i or l.description.to_s =~ /no\-fee|no\s+fee/i
        l.update_column :no_fee, true
      end
    end
  end
end
