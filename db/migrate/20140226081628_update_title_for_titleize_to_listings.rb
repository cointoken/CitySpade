class UpdateTitleForTitleizeToListings < ActiveRecord::Migration
  def change
    Listing.all.each do |listing|
      unless listing.save
        listing.destroy
      end
    end
  end
end
