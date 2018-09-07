class ListingImageObserver < ActiveRecord::Observer
  def after_create(img)
    if img.origin_url.include?('mlspin.com') && img.origin_url.include?('&n=1')
      ListingImage.unscoped.where(listing_id: img.listing_id, origin_url: img.origin_url.split('&').first).destroy_all
      # ListingImage.where(origin)
    end
  end
end
