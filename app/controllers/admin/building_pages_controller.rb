class Admin::BuildingPagesController < Admin::BaseController
  before_action :get_building, only: [:add_images, :create_images, :add_floorplan, :create_floorplan]
  before_filter :require_office

  def add_images
    @images = @building.building_images
  end

  def create_images
    respond_to do |format|
      @buildingimage = @building.building_images.create(building_params)
      format.js { render layout: false }
    end
  end

  def add_floorplan
  end

  def create_floorplan
    respond_to do |format|
      @floorplan = @building.floorplans.create(floorplan_params)
      format.js { render layout: false }
    end

  end

  def delete_bimage
    bimage = BuildingImage.find params[:id]
    building_id = bimage.building_id
    if bimage.destroy
      flash[:notice] = "Removed successfully"
    else
      flash[:alert] = "Something went wrong"
    end
    redirect_to add_images_admin_building_page_path(building_id)
  end

  def delete_fplan
    fplan = Floorplan.find params[:id]
    building_id = fplan.building_id
    if fplan.destroy
      flash[:notice] = "Removed successfully"
    else
      flash[:alert] = "Something went wrong"
    end
    redirect_to add_floorplan_admin_building_page_path(building_id)
  end

  def edit_fplan
    @fplan = Floorplan.find params[:id]
    building_id = @fplan.building_id
    if request.put?
      @fplan.update(floorplan_params)
      redirect_to add_floorplan_admin_building_page_path(building_id)
    end
  end

  def set_cover
    image = BuildingImage.find params[:id]
    image.cover = true
    if image.save
      redirect_to :back, notice: "Image set as cover"
    else
      redirect_to :back, alert: "Something went wrong"
    end
  end

  private


  def get_building
    @building = Building.friendly.find params[:id]
  end

  def building_params
    params.require(:building_image).permit(:image)
  end

  def floorplan_params
    params.require(:floorplan).permit(:image, :beds, :baths, :price, :sqft)
  end


end
