class AccountsController < ApplicationController
  # load_and_authorize_resource except: :change_password
  before_filter :authenticate_account!, except: :check_facebook_login
  before_action :require_office_account, only: [:listings]
  def show
    if current_account.present?
      @buildings =  Building.joins(:reputations).where("reputations.account_id = ?", current_account.id)
      #@listings = Listing.joins(:reputations).
      #  where("reputations.account_id = ?", current_account.id).
      #  page(params[:page]||1).per(8)
    else
      redirect_to new_account_session_path
    end
  end

  def listings
    if params[:status] == Settings.listing_status.actived
      @listings = current_account.listings.where(status: [0, -1])
    else
      @listings = current_account.listings.expired
    end
  end

  def verify_office
    @account = Account.find_by_email(params[:email])
    @account.add_office_token
    if @account.office_token.present?
      MailNotifyWorker.perform_async(@account.id, :verify_office_account, {})
      redirect_to new_listing_path, notice: "The email has been sent successfully."
    else
      redirect_to new_listing_path, notice: "The email failed to send."
    end
  end

  def saved_wishlist
    @buildings = Building.joins(:reputations).where("reputations.account_id = ?", current_account.id)
    #@listings = Listing.enables.joins(:reputations).
    #  where("reputations.account_id = ?", current_account.id).
    #  where(flag: get_rental_or_sale_id).order('listings.id desc').
    #  page(params[:page]||1).per(8)
  end

  def past_wishlist
    @listings = Listing.expired.joins(:reputations).
      where("reputations.account_id = ?", current_account.id).
      where(flag: get_rental_or_sale_id).order('listings.id desc').
      page(params[:page]||1).per(8)
  end

  def room_wishlist
    @rooms = Room.active.joins(:reputations).
      where("reputations.account_id=?", current_account.id).
      where("reputations.category=?","Room").
      page(params[:page]||1).per(8)
  end

  def my_room_postings
    collection = Room.where(account_id: current_account.id)
    Roommate.where(account_id: current_account.id).each{|r| collection << r}
    all_posts = collection.sort_by(&:created_at).reverse
    @posts = Kaminari.paginate_array(all_posts).page(params[:page]).per(8)

  end

  def applications
    @client_applies = current_account.get_client_applies    
  end

  def check_facebook_login
    if current_account && current_account.logined_facebook?
      render json: {logined: true}
    else
      render json: {logined: false}
    end
  end

  def account_params
    params.require(:account).permit(devise_parameter_sanitizer.for(:sign_up))
  end

  def require_office_account
    unless current_account.present? && (current_account.is_office_account? or current_account.admin?)
      redirect_to :back, alert: "You don't have permission to access this page."
    end
  end

  #def agents
  #  @agents = Account.where(role: 'agent')
  #  @office_addresses = @agents.pluck(:office_address).uniq
  #  @languages = @agents.pluck(:languages).reject(&:blank?).map{|a|a.split(',')}.flatten.uniq

  #  if params[:agent].present? && params[:agent][:name].present?
  #    @agents = @agents.where('LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ?', "%#{params[:agent][:name].downcase}%", "%#{params[:agent][:name].downcase}%")
  #  end

  #  if params[:agent].present? && params[:agent][:office_address].present?
  #    @agents = @agents.where('office_address LIKE ?', "%#{params[:office_address]}%")
  #  end

  #  if params[:agent].present? && params[:agent][:languages].present?
  #    @agents = @agents.where('languages LIKE ?', "%#{params[:languages]}%")
  #  end
  #  @agents = Kaminari.paginate_array(@agents).page(params[:page]).per(9)
  #  respond_to do|format|
  #    if request.xhr?
  #      format.js
  #    else
  #      format.html
  #    end
  #  end
  #end
end
