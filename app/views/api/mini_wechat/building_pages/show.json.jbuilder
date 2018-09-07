json.extract! @building, :id,
                         :name,
                         :political_area_id,
                         :zipcode,
                         :address,
                         :city,
                         :block,
                         :lot,
                         :description,
                         :created_at,
                         :updated_at,
                         :amenities,
                         :price,
                         :lat,
                         :lng
json.set! :schools,
  if @building.schools.present?
    @building.schools.split(',')
  else
    []
  end
json.set! :images,
  if @building.building_images.present?
    @building.building_images.map(&:image_url)
  else
    []
  end
json.set! :floorplans, @building.floorplans.to_a
json.set! :like, (@like.blank? or @like == 0) ? 0 : 1
