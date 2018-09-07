class ClearCitiHabitatsRepeatListings < ActiveRecord::Migration
  def change
    Listing.where('origin_url like ?', '%www.citi-habitats%').each do |listing|
      opt = {
              beds: listing.beds, baths: listing.baths,
              price: listing.price, unit: listing.unit,
              formatted_address: listing.formatted_address,
              flag: listing.flag
              }
      Listing.where('id > ?', listing.id).where(opt).destroy_all
    end
    Listing.where('lat = 0 or lng = 0').destroy_all
  end
end
