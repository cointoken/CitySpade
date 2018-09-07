class Api::MiniWechat::BuildingPagesController < ActionController::Base
  def index
    @building_pages = search_buildings.select(*select_columns)
  end

  def show
    @user = MiniWechatUser.find_by_open_id(params[:open_id])
    if @user.present?
      @like = @user.likeables.where(collection_id: params[:id], collection_type: "Building").first.try(:like)
    else
      @like = 0
    end
    @building = Building.includes(:floorplans).find(params[:id])
  end

  def collect_building
    user = MiniWechatUser.find_by_open_id(params[:open_id])
    @res = user.collect_building(params[:id])
  end

  def uncollect_building
    user = MiniWechatUser.find_by_open_id(params[:open_id])
    @res = user.uncollect_building(params[:id])
  end

  private

  def search_buildings
    buildings = Building.enables
    if params[:city]
      city = city_fomatten params[:city]
      buildings = buildings.where('formatted_address like ?', "%#{city}%")
    end
    if params[:query]
      city = city_fomatten params[:query]
      buildings = buildings.where('formatted_address like ? OR name like ?', "%#{city}%", "%#{params[:query]}%")
    end
    buildings = buildings.includes(:building_images).order(id: :desc)
    buildings
  end

  def select_columns
    @select_columns ||= [:id, :name, :city, :block, :lot, :zipcode, :address, :owner_name, :owner_type,
                         :num_floors, :units_res, :units_total, :lot_front, :lot_depth, :year_built, :description,
                         :amenities, :lat, :lng];
  end

  def city_fomatten city
    if city.strip.upcase == 'NYC'
      return 'New York'
    end
    return city
  end

end
