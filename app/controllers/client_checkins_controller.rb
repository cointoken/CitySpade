class ClientCheckinsController < ApplicationController

  before_filter :require_admin
  before_action :set_flag, only: [:edit, :update]

  def new
    @client = ClientCheckin.new
    @client.client_roommates.build
  end

  def create
    @client = ClientCheckin.new(client_params)
    if @client.save
      redirect_to @client
    else
      flash[:alert] = @client.errors.full_messages.join(",")
      if @client.client_roommates.empty?
        @client.client_roommates.build
      end
      render :new
    end
  end

  def show
    @client = ClientCheckin.find params[:id]
  end

  def edit
    @client = ClientCheckin.find params[:id]
  end

  def update
    @client = ClientCheckin.find params[:id]
    if @client.update_attributes(client_params)
      redirect_to admin_client_checkins_path
    else
      flash[:alert] = @client.errors.full_messages.join(",")
      render :edit
    end
  end

  def destroy
    @client = ClientCheckin.find params[:id]
    if @client.destroy
      flash[:notice] = "Deleted Succesfully"
      redirect_to admin_client_checkins_path
    else
      flash[:alert] = "Something went wrong"
      redirect_to admin_client_checkins_path
    end
  end

  private

  def client_params
    params.require(:client_checkin).permit(:first_name, :last_name, :email, :phone, client_roommates_attributes: [:id, :first_name, :last_name], checkin_buildings_attributes: [:id, :name, :unit]) 
  end


  def require_admin
    unless (current_account.present? and current_account.can_manage_site?)
      raise CanCan::AccessDenied
    end
  end

  def set_flag
    @building_edit = true
  end

end
