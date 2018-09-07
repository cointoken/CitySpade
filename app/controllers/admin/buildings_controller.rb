class Admin::BuildingsController < Admin::BaseController
  before_action :set_admin_building, only: [:show, :edit, :update, :destroy, :relate_listings]
  before_filter :require_office
  # GET /admin/buildings
  # GET /admin/buildings.json
  def index
    @buildings = Building.all
    @count = @buildings.count
    if params[:sort].present?
      @buildings = @buildings.order("#{sort_column} #{sort_direction}")
    else
      @buildings = @buildings.order(id: :desc)
    end
    @buildings = @buildings.where city: params[:city]  if params[:city].present?
    @buildings = @buildings.where state: params[:state]  if params[:state].present?
    if params[:street_name].present?
      addr = "#{params[:street_name].strip}"
      @buildings = @buildings.where("address like ?", "%#{addr}%")
      #if addr =~ /^\d/
      #  @buildings = @buildings.where("address like ?", "#{addr}%")
      #else
      #  @buildings = @buildings.where("address like ?", "%#{addr}%")
      #end
      #if @buildings.blank? && params[:street_name].present?
      #  building = AddressTranslator.find_building_from_address_translator addr, params.slice(:city, :borough)
      #  if building
      #    @buildings = Building.where(id: building.id).page params[:page]
      #  end
      #end
    end
    @buildings = @buildings.page params[:page]
  end

  # GET /admin/buildings/1
  # GET /admin/buildings/1.json
  def show
  end

  # GET /admin/buildings/new
  def new
    @building = Building.new
    # @admin_building = Admin::Building.new
  end

  # GET /admin/buildings/1/edit
  def edit
  end

  def relate_listings
    @building.set_relate_listings
    render action: :show
  end

  # POST /admin/buildings
  # POST /admin/buildings.json
  def create
    @building = Building.new(admin_building_params)

    respond_to do |format|
      if @building.save
        format.html { redirect_to admin_building_path(@building), notice: 'Building was successfully created.' }
        format.json { render :show, status: :created, location: @building }
      else
        format.html { render 'new' }
        format.json { render json: @building.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/buildings/1
  # PATCH/PUT /admin/buildings/1.json
  def update
    respond_to do |format|
      if @building.update(admin_building_params)
        format.html { redirect_to admin_building_path(@building), notice: 'Building was successfully updated.' }
        format.json { render :show, status: :ok, location: @building }
      else
        format.html { render :edit }
        format.json { render json: @building.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/buildings/1
  # DELETE /admin/buildings/1.json
  def destroy
    @admin_building = Building.find params[:id]
    @admin_building.destroy
    respond_to do |format|
      format.html { redirect_to admin_buildings_url, notice: 'Building was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_admin_building
    @building = Building.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def admin_building_params
      params.require(:building).permit(:city, :state, :name, :address, :year_built, :units_total, :description, :apt_amenities, :neighborhood, :haveop, amenities: [], schools: [])
  end
end
