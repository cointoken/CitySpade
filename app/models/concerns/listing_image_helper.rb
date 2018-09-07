module ListingImageHelper
  def check_url_valid?
    if self.listing
      if self.listing.broker_site_name == 'citi-habitats'
        if !self.origin_url || !self.origin_url.include?(self.listing.origin_listing_id)
          errors.add(:origin_url, 'url is not active')
          return false
        end
      end
    end
    true
  end
  def self.included(base)
    base.validate :check_url_valid?, on: :create
    base.scope :floorplans, -> {base.where('listing_images.floorplan = true')}
    base.scope :listing_pic, -> {base.where('listing_images.floorplan = false')}
  end
end
