class ListingUrl < ActiveRecord::Base
  belongs_to :listing
  after_save :set_default_url_for_listing
  after_destroy :destroy_default_from_listing_url
  def set_default_url_for_listing
    if self.listing.listing_url_id.blank? || self.listing.listing_url_id == self.id || self.listing.origin_url == self.url
      self.listing.update_columns listing_url_id: self.id, origin_url: self.url
    end
  end
  def destroy_default_from_listing_url
    if self.listing.listing_url_id == self.id
      self.listing.update_columns listing_url_id: self.listing.urls.first.try(:id) || nil, origin_url: self.listing.urls.first.try(:url) || nil
    end
  end

end
