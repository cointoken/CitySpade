class Admin::RoommatesController < Admin::BaseController
  before_action :set_admin_roommate, only: [:show, :edit, :update, :destroy]
  before_filter :require_admin

  # GET /admin/roommates
  # GET /admin/roommates.json
  def index
    @roommates = Roommate.unscoped.all
    if params[:sort].blank?
      @roommates = @roommates.order('created_at desc').page(params[:page]).per(10)
    else
      @roommates = @roommates.unscoped.order("#{sort_column} #{sort_direction}").page(params[:page]).per(10)
    end
    @roommates = @roommates.where(id: params[:id]) unless params[:id].blank?
  end

  # GET /admin/roommates/1
  # GET /admin/roommates/1.json
  def show
  end

  # GET /admin/roommates/new
  def new
    @roommate = Roommate.new
  end

  # GET /admin/roommates/1/edit
  def edit
    @roommate = Roommate.find(params[:id])
  end

  def expire
    @roommate = Roommate.find(params[:id])
    @roommate.expired!
    redirect_to admin_roommates_path, notice: "Successfully expired roommate request"
  end

  # POST /admin/roommates
  # POST /admin/roommates.json
  def create
    @admin_roommate = Roommate.new(admin_roommate_params)

    respond_to do |format|
      if @admin_roommate.save
        format.html { redirect_to @admin_roommate, notice: 'Roommate was successfully created.' }
        format.json { render action: 'show', status: :created, location: @admin_roommate }
      else
        format.html { render action: 'new' }
        format.json { render json: @admin_roommate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/roommates/1
  # PATCH/PUT /admin/roommates/1.json
  def update
    respond_to do |format|
      if @admin_roommate.update(admin_roommate_params)
        format.html { redirect_to admin_roommates_path, notice: 'Roommate was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @admin_roommate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/roommates/1
  # DELETE /admin/roommates/1.json
  def destroy
    @admin_roommate.destroy
    respond_to do |format|
      format.html { redirect_to admin_rooms_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_roommate
      @admin_roommate = Roommate.unscoped.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_roommate_params
       params.require(:roommate).permit(
      :gender, :budget, { :pets_allowed => [],:borough => [] }, :about_me,
      :students_only, :raw_neighborhood,
      :title, :num_roommates, :location, :move_in_date,
      :duration
    )
    end
end
