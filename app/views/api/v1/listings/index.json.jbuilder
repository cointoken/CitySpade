json.array!(@listings) do |listing|
  json.extract! listing, *listing_params[:index]
  json.set! :title, listing.display_title
  json.set! :bargain, display_score(listing, :score_price)# || 8.5}/10"
  json.set! :transportation, display_score(listing, :score_transport)
  json.set! :images, 
    if listing.listing_image_id.present? 
      [{sizes: listing.image_sizes, url: listing.image_base_url}]
    else
      [{sizes: [], url: listing_default_image_url}]
    end 
  end
