json.set! :listings, @listings.map do |listing|
  json.extract! listing, *listing_params[:index]
  json.set! :title, listing.display_title
  json.set! :bargain, display_score_for_api(listing, :score_price)# || 8.5}/10"
  json.set! :transportation, display_score_for_api(listing, :score_transport)
  json.set! :images, 
    if listing['listing_image_id'].present? 
      [{sizes: listing['image_sizes'], url: listing['image_base_url']}]
  else
    [{sizes: [], url: listing_default_image_url}]
  end 
end
json.set! :total_count, @listings.try(:total_count) || @listings.size
