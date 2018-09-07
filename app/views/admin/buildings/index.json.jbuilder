json.array!(@admin_buildings) do |admin_building|
  json.extract! admin_building, :id
  json.url admin_building_url(admin_building, format: :json)
end
