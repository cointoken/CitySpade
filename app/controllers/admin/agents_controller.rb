class Admin::AgentsController <  Admin::BaseController
  before_action :set_agent, only: [:show, :edit, :update, :destroy]
  before_filter :require_admin

  # GET /admin/brokers
  # GET /admin/brokers.json
  def index
    @agents = Agent.where(active: true)
    if params[:sort].blank?
      @agents = @agents.order(id: :desc).page(params[:page]).per 20
    else
      @agents = @agents.order("#{sort_column} #{sort_direction}").page(params[:page]).per 20
    end
    #@agents = @agents.where("agents.name like ?", "%#{params[:name]}%") unless params[:name].blank?
    #@agents = @agents.where("brokers.name like ?", "%#{params[:broker_name]}%") unless params[:broker_name].blank?
    #@agents = @agents.where("agents.tel like ?", "%#{params[:tel]}%") unless params[:tel].blank?
    #@agents = @agents.where("agents.email like ?", "%#{params[:email]}%") unless params[:email].blank?
  end

  # GET /admin/brokers/1
  # GET /admin/brokers/1.json
  def show
  end

  # GET /admin/brokers/new
  def new
    @agent = Agent.new
  end

  # GET /admin/brokers/1/edit
  def edit
    @agent = Agent.find params[:id]
  end

  # POST /admin/brokers
  # POST /admin/brokers.json
  def create
    @agent = Agent.new(agent_params)
    creat_agentlanguage(@agent)
    respond_to do |format|
      if @agent.save
        format.html { redirect_to @agent, notice: 'Agent was successfully created.' }
        format.json { render action: 'show', status: :created, location: @agent}
      else
        format.html { render action: 'new' }
        format.json { render json: @agent.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/brokers/1
  # PATCH/PUT /admin/brokers/1.json
  def update
    creat_agentlanguage(@agent)
    respond_to do |format|
      if @agent.update(agent_params)
        format.html { redirect_to admin_agent_path(@agent), notice: 'Agent was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @agent.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/brokers/1
  # DELETE /admin/brokers/1.json
  def destroy
    @agent.destroy
    respond_to do |format|
      format.html { redirect_to admin_agents_url }
      format.json { head :no_content }
    end
  end

  def creat_agentlanguage(agent)
    params[:languages].each do |l|
      agent.languages << Language.find(l)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_agent
      @agent = Agent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def agent_params
      params.require(:agent).permit(:name, :tel, :email, :wechat, :address, :active, :photo, :introduction, :experience)
    end
end
