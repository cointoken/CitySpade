if params[:flag] == 'simple'
  json.extract! @listing, *listing_params[:index]
  json.set! :bargain, display_score_for_api(@listing, :score_price)# || 8.5}/10"
  json.set! :transportation, display_score_for_api(@listing, :score_transport)
  json.set! :images, 
    if @listing['listing_image_id'].present? 
      [{sizes: @listing['image_sizes'], url: @listing['image_base_url']}]
  else
    [{sizes: [], url: listing_default_image_url}]
  end 
else
  if params[:flag] == 'full'
    json.extract! @listing, *listing_params[:index]
    json.set! :bargain, display_score_for_api(@listing, :score_price)# || 8.5}/10"
    json.set! :transportation, display_score_for_api(@listing, :score_transport)
    json.set! :images, 
      if @listing['listing_image_id'].present? 
        [{sizes: @listing['image_sizes'], url: @listing['image_base_url']}]
    else
      [{sizes: [], url: listing_default_image_url}]
    end 
  end
  json.extract! @listing, :contact_name, :contact_tel
  json.set! :original_url, @listing.final_url
  json.set! :original_icon_url, asset_url(@listing.broker_icon_url)
  json.set! :subway_lines, @listing.subway_lines_order_by_color.map do |l|
    json.extract! l, :lat, :lng, :station_name, :line_name, :duration_text, :distance_text
    json.set! :icon_url, asset_url(l.icon_url)
  end
  json.set! :bus_lines, @listing.bus_lines.map do |l|
    json.extract! l, :lat, :lng, :station_name, :line_name, :duration_text, :distance_text
  end
  json.set! :hottest_spots, (@listing.political_area.try(:hottest_spots) || []).map do |spot|
    distance = @listing.trans_by_place spot
    json.extract! spot, :name, :lat, :lng
    if distance
      json.set! :time, "#{(distance.duration / 60).ceil} min"
    else
      json.set! :time, "NA min"
    end
    json.set! :transt_type_icon, transt_type_icon_url(distance.try :mode)
  end
  json.set! :colleges, (@listing.political_area.try(:colleges) || []).map do |college|
    distance = @listing.trans_by_place college
    json.extract! college, :name, :lat, :lng
    if distance
      json.set! :time, "#{(distance.duration / 60).ceil} min"
    else
      json.set! :time, "NA min"
    end
    json.set! :transt_type_icon, transt_type_icon_url(distance.try :mode)
  end
end
