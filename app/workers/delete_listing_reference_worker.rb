class DeleteListingReferenceWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  def perform(listing_id)
    listing = Listing.find listing_id
    return if listing.is_enable?
    listing.listing_mta_lines.delete_all
    listing.listing_places.delete_all
    listing.transport_distances.delete_all
    #listing.images.destroy_all
    listing.update_columns :status, 10, place_flag: 0
  end
end
