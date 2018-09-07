class Admin::RoomsController < Admin::BaseController
  before_action :set_admin_room, only: [:show, :edit, :update, :destroy]
  before_action :init_gon, only: [:new, :edit]
  before_action :set_custom_formId, only: [:new, :edit]
  before_filter :require_admin

  # GET /admin/rooms
  # GET /admin/rooms.json
  def index
    @rooms = Room.unscoped.all
    if params[:sort].blank?
      @rooms = @rooms.order('created_at desc').page(params[:page]).per(10)
    else
      @rooms = @rooms.unscoped.order("#{sort_column} #{sort_direction}").page(params[:page]).per(10)
    end
    @rooms = @rooms.where(id: params[:id]) unless params[:id].blank?
  end

  # GET /admin/rooms/1
  # GET /admin/rooms/1.json
  def show
  end

  # GET /admin/rooms/new
  def new
    @admin_room = Room.new
    @room_detail = @admin_room.room_detail
  end

  # GET /admin/rooms/1/edit
  def edit
    @admin_room = Room.find(params[:id])
    @room_detail = @admin_room.room_detail
    @images = @admin_room.photos.map(&:image)
  end

  def expire
    @room = Room.find(params[:id])
    @room.expired!
    redirect_to admin_rooms_path, notice: "Successfully expired Room Offer"
  end

  # POST /admin/rooms
  # POST /admin/rooms.json
  def create
    @admin_room = Room.new(admin_room_params)
    @room_detail = @admin_room.room_detail

    respond_to do |format|
      if @admin_room.save
        format.html { redirect_to @admin_room, notice: 'Room was successfully created.' }
        format.json { render action: 'show', status: :created, location: @admin_room }
      else
        format.html { render action: 'new' }
        format.json { render json: @admin_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/rooms/1
  # PATCH/PUT /admin/rooms/1.json
  def update
    respond_to do |format|
      if @admin_room.update(admin_room_params)
        format.html { redirect_to admin_rooms_path, notice: 'Room was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @admin_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/rooms/1
  # DELETE /admin/rooms/1.json
  def destroy
    @admin_room.destroy
    respond_to do |format|
      format.html { redirect_to admin_rooms_url }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_admin_room
    @admin_room = Room.unscoped.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def admin_room_params
    params_hash = params.require(:room).permit(
      :room_type, :title, :street_address, :city, :zipcode, :bedrooms,
      :bathrooms, :available_begin_at, :available_end_at, :state, :price_month,
      :rooms_available, :photos,
      :room_detail_attributes => [
        {:amenities => []},
        {:pets_allowed => []},
        :description
      ]
    )

    params_hash[:price_month] = params_hash[:price_month].split(".")[0].gsub(/[^0-9]/,'')
    params_hash
  end

  def init_gon
   gon.ajax_urls ||= []
   if params[:id]
     gon.ajax_urls << photos_info_photos_path(obj_type: controller_name.classify, obj_id: params[:id])
   else
     gon.ajax_urls << photos_info_photos_path
   end
  end

  def set_custom_formId
    gon.imageFormId = "#roomImageForm"
  end
end
