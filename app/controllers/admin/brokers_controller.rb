class Admin::BrokersController <  Admin::BaseController
  before_action :set_broker, only: [:show, :edit, :update, :destroy]
  before_filter :require_admin

  # GET /admin/brokers
  # GET /admin/brokers.json
  def index
    brokers = Broker.order("tel is null desc ").order("email is null desc").order(listing_num: :desc)
    if params[:sort].blank?
      @brokers = brokers.order(:name).page(params[:page]).per 20
    else
      @brokers = brokers.order("#{sort_column} #{sort_direction}").page(params[:page]).per 20
    end
    if params[:state].present?
      @brokers = @brokers.where(state: params[:state])
    end
    @brokers = @brokers.where("name like ?", "%#{params[:name]}%") unless params[:name].blank?
    @brokers = @brokers.where("tel like ?", "%#{params[:tel]}%") unless params[:tel].blank?
    @brokers = @brokers.where("email like ?", "%#{params[:email]}%") unless params[:email].blank?
  end

  # GET /admin/brokers/1
  # GET /admin/brokers/1.json
  def show
  end

  # GET /admin/brokers/new
  def new
    @broker = Broker.new
  end

  # GET /admin/brokers/1/edit
  def edit
  end

  # POST /admin/brokers
  # POST /admin/brokers.json
  def create
    @broker = Broker.new(broker_params)

    respond_to do |format|
      if @broker.save
        format.html { redirect_to @broker, notice: 'Broker was successfully created.' }
        format.json { render action: 'show', status: :created, location: @broker }
      else
        format.html { render action: 'new' }
        format.json { render json: @broker.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/brokers/1
  # PATCH/PUT /admin/brokers/1.json
  def update
    respond_to do |format|
      if @broker.update(broker_params)
        format.html { redirect_to admin_broker_path(@broker), notice: 'Broker was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @broker.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/brokers/1
  # DELETE /admin/brokers/1.json
  def destroy
    @broker.destroy
    respond_to do |format|
      format.html { redirect_to admin_brokers_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_broker
      @broker = Broker.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def broker_params
      params.require(:broker).permit(:name, :tel, :email)
    end
end
