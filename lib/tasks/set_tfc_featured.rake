namespace :set do
  desc "Setting certain set of TFC apartments to be constantly featured"
  task set_TFC_featured: :environment do
  	all_listings = Broker.find_by(name: "TF Cornerstone, Inc.").listings
  	all_listings.each do |l|
  		l.featured_for(3)
  	end
  end
end