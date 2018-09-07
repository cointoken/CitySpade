json.array!(@cities) do |city|
  json.set! :id, city.id
  json.set! :name, city.long_name
  json.set! :lat, city.lat
  json.set! :lng, city.lng
end
