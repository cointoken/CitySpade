json.array!(@listings) do |listing|
  json.extract! listing, :score_transport, :score_price, :baths, :title, :lat, :lng, :id, :price
  json.beds listing.display_beds
  json.set! :small_image_url, listing_image_url(listing, '60X60') # .image_url('300X180')
  json.set! :price_k, listing.price_k
end

