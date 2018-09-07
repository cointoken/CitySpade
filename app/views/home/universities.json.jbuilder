json.buildings do
  json.array!(@univs) do |univ|
    json.name univ.name
  end
end
