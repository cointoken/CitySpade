json.array!(@building_pages) do |building|
  json.set! :id, building.id
  json.set! :name, building.name
  json.set! :city, building.city
  json.set! :address, building.address
  json.set! :price, building.price
  json.set! :images,
    if building.building_images.present?
      building.building_images.first.image_url(:thumb)
    else
      ""
    end
  end
