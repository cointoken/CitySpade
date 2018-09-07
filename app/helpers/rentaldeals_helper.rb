module RentaldealsHelper

  def deals_image_url(listing)
    if !listing.images.blank?
      image = listing.images.first
      image.url.remove("origin") + '360X240'
    end
  end

  def deals_or_default_url(listing, target=nil)
    deals_image_url(listing) || listing_default_image_url(target)
  end
end
