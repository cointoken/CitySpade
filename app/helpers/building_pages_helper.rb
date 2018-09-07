module BuildingPagesHelper

  def building_thumb images
    if images.length > 0
      img = images.find_by(cover: true)
      if img.present?
        image_tag img.image_url(:thumb)
      else
        image_tag images.first.image_url(:thumb)
      end
    else
      image_tag 'default.jpg'
    end
  end
  
  def price_search(min, max, buildings)
    buildings.joins(:floorplans).where("floorplans.price > ? AND floorplans.price < ?", min, max).group("buildings.id")
  end

  def location_search(location, buildings)
    if location == "NY"
      buildings.where("city = ? or city = ? or city=? or city=?", "New York", "Brooklyn", "Bronx", "Queens")
    else
      buildings.where("formatted_address like ?", "%#{location}%")
    end
  end

  def school_search(name)
    base = TransportPlace.find_by(name:  name)
    if base.state == "NY"
      Building.within(3, units: :miles, origin: [base.lat, base.lng]).by_distance(origin: [base.lat, base.lng])
    else
      Building.within(10, units: :miles, origin: [base.lat, base.lng]).by_distance(origin: [base.lat, base.lng])
    end
  end

  def get_floorplans(building)
    building.floorplans.pluck(:beds).uniq.sort
  end

end
