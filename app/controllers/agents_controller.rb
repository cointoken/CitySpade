class AgentsController < ApplicationController
  def show
    @agent = Agent.find(params[:id])
    #@listings = @agent.listings.enables.order(id: :desc).page(params[:page]).per(10)

    @page_title = "#{@agent.name} - Agent"
    if params[:page]
      @page_title << ", Page #{params[:page]}"
    end
    @page_title << " | CitySpade"
    @page_description = @agent.remark.try(:limit, 120)
  end

  def index
    @agent_show = Agent.where(active: true)
    if !params[:agent].nil?
      @agent_show = @agent_show.where("name like ?", "%#{params[:agent][:name]}%") unless params[:agent][:name].blank?
      @agent_show = @agent_show.where("address = ?", "%#{params[:agent][:office_address]}%") unless params[:agent][:office_address].blank?
      @agent_show = @agent_show.joins(:languages).where("languages.name = ?", "#{params[:agent][:languages]}") unless params[:agent][:languages].blank?
    end
    @agents = @agent_show
    if mobile?
      @agents = Kaminari.paginate_array(@agents).page(params[:page]).per(2)
    else
      @agents = Kaminari.paginate_array(@agents).page(params[:page]).per(9)
    end
    respond_to do|format|
      if request.xhr?
        format.js
      else
        format.html
      end
    end

  end

  def contact_agent
    @agent = Agent.find params[:agent_id]
    info = contact_params
    respond_to do |format|
      if ContactMailer.contact_agent(info, @agent).deliver
        format.js
      else
        format.html
      end
    end
  end

  private

  def contact_params
    params.permit(:Message, :Name, :Email, :Phone)
  end

end
