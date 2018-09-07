class Admin::PoliticalAreasController <  Admin::BaseController
  before_filter :require_admin

  # GET /admin/political_area
  # GET /admin/political_area.json
  def index
    @political_areas = PoliticalArea.all
    if params[:city_id].present?
      @political_areas = PoliticalArea.find(params[:city_id]).sub_areas
    end
    @political_areas = @political_areas.where("long_name like ?", "%#{params[:long_name]}%") if params[:long_name]
    @political_areas = @political_areas.page params[:page]
  end

  def edit
    @political_area = PoliticalArea.find(params[:id])
  end

  def destroy
    @political_area = PoliticalArea.find(params[:id])
    @political_area.destroy
    redirect_to admin_political_areas_path
  end

  def update
    @political_area = PoliticalArea.find(params[:id])
    respond_to do |format|
      if @political_area.update(political_area_params)
        format.html { redirect_to admin_political_areas_path, notice: 'Political Area was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @political_area.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def political_area_params
    params.require(:political_area).permit(:id, :second_name)
  end
end
