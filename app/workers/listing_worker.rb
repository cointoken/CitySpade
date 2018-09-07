class ListingWorker 
  include Sidekiq::Worker
  sidekiq_options retry: false
  def perform(listing_id, target  = nil)
    case target.to_sym
    when :improve
      listing = Listing.find listing_id
      listing.cal_transit
    else
      unless $redis.get("l##{listing_id}")
        listing = Listing.find listing_id
        if listing.listing_places.present?
          listing.listing_places.destroy_all
          listing.listing_mta_lines.where('listing_place_id is not null').destroy_all
          MapsServices::RetrieveListingMtaLine.setup listing
        end
        if listing.score_transport.blank?
          MapsServices::CalTransportDistance.setup listing
          if listing.city.long_name == 'New York'
            if ['queens', 'brooklyn'].include? listing.political_area.borough.long_name.downcase
              MapsServices::TransportScore.send listing.political_area.borough.long_name.downcase, query:{id: listing.id}
            else
              MapsServices::TransportScore.manhattan query:{id: listing.id}
            end
          else
            MapsServices::TransportScore.philadelphia query: {id: listing.id}
          end
        end
        $redis.set("l##{listing_id}", true)
      end
    end
  end
end
