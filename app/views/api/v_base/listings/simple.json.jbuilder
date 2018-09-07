json.set! :listings, @listings.map do |listing|
  json.extract! listing, :id, :lat, :lng
 end
json.set! :total_count, @listings.try(:total_count) || @listings.size
