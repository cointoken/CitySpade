class ReviewWorker
  include Sidekiq::Worker
  sidekiq_options retry: true
  def perform(id, target = :create_venue, review_id = nil)
    venue = get_venue_by_id id, review_id
    case target.to_sym
    when :create_venue
      venue.set_region true
      venue.set_ratings true
    when :update_ratings
      venue.set_ratings true
      parent_ids = venue.rel_neighborhood_venues.where('id != ?', venue.id).map{|v|
        v.parent_ids(include_self: true)
      }.flatten.compact.uniq
      if parent_ids.present?
        Venue.where(id: parent_ids).each{|s| s.set_ratings true}
      end
      #while parent
        #parent.set_ratings true
        #parent = parent.parent
      #end
    end
    if venue.building?
      if venue.reviews.count == 0
        Listing.where(building_venue_id: venue.id).update_all building_venue_id: nil
      else
        Listing.enables.where(building_venue_id: nil).where('formatted_address like ?', "#{venue.geo_like_address}%")
          .update_all building_venue_id: venue.id
      end
    end
  end

  def get_venue_by_id(id, review_id)
    limit = 10
    i = 0
    begin
      i += 1
      if review_id && !Review.unscoped.exists?(id: review_id, venue_id: id)
        sleep 2
        next
      end
      venue = Venue.find_by_id id
      sleep 2
    end while !venue && i < limit
    venue
  end
end
