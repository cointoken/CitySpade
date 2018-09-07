namespace :up do
  desc "Update the transport places"
  task transport_update: :environment do
  
    list = Array.new
    all_listings = Listing.where(status: 0).where(score_transport: nil)
    all_listings.each do |x|
      if x.state.try(:short_name) == "NY"
        list << x
      end
    end
    n = list.length - 100

    list[n..-1].each do |listing|
      listing.cancel_cal_transport_distances
      puts listing.id
      listing.cal_score
    end
  
  end
end
