json.array!(@collect_buildings) do |building|
  json.set! :id, building.id
  json.set! :name, building.name
  json.set! :city, building.city
  json.set! :address, building.address
  json.set! :price, building.price
  json.set! :images,
    if building.building_images.present?
      building.building_images.first.image_url
    else
      ""
    end
  end
