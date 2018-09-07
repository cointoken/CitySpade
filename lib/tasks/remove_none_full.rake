namespace :set do
  desc "Remove all non_full adress listings"
  task remove_none_full_address: :environment do
  	all_listings = Listing.where(is_full_address: false).where(status: 0)
  	all_listings.each do |l|
  		l.update(status: 1)
  	end
  end
end