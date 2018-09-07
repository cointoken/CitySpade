class SearchForMeController < ApplicationController
  before_action :set_referral, only: [:new]

  def new
    @form_info = SearchForMe.new
  end

  def create
    @form_info  = SearchForMe.new(form_info_params)
    #email_test = true
    #if EmailVerifier.check(@form_info.email) != true
    #  email_test = false
    #  flash[:alert] = "Type in real email address please"
    #  redirect_to :back
    #end
    if @form_info.save
      RoomContactMailer.search_for_me_email(@form_info).deliver
      if form_info_params[:referral]
        RoomContactMailer.dealmoon_reply(@form_info.name, @form_info.email).deliver
      end
      RoomContactMailer.delay.building_suggestion(@form_info)
      redirect_to @form_info
    else
      redirect_to :back
    end
  end

  def show
    @form_info = SearchForMe.find(params[:id])
  end

  def refer_dealmoon
    redirect_to new_search_for_me_path(refer: true)
  end

  
  private

  def set_referral
    @referral = params[:refer] || false
  end

  def form_info_params
    params.require(:form_info).permit(:name, :beds, :baths, :budget, :move_in_date, :is_employed, :email, :referral, :wechat, transportation: [], boroughs:[])
  end
end
