class SeedDisplayBedsToListings < ActiveRecord::Migration
  def change
    Listing.all.each do |l|
      l.update_column(:display_beds, l.read_beds.ceil)
    end
  end
end
