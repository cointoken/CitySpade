json.buildings do
  json.array!(@buildings) do |building|
    json.name building.name
    json.address building.formatted_address
    json.url building_page_path(building)
  end
end
