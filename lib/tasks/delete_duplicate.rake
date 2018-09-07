namespace :rm do
  desc "Delete duplicate listing and keep TFC"
  task delete_duplicate: :environment do

    #Add Street addresses here
    
    format_addr = ["2 Gold Street"]
    alternate_addr = ["2 Gold St"]

    format_addr.each_with_index do |val, index|
      listings = Listing.where('formatted_address like ? or formatted_address like ? or street_address like ?',"%#{val}%","%#{alternate_addr[index]}%",val)
      listings = listings.where(status: 0)
      del_listings = listings.where.not(broker_id: 3630)
      del_listings.update_all(status: 1)
    end
  end
end
