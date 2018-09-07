class Admin::ClientCheckinsController < Admin::BaseController
  before_filter :require_admin

  def index
    firstname = params[:first_name]
    lastname = params[:last_name]
    @clients = ClientCheckin.all
    if firstname || lastname
      @clients = @clients.where("first_name like ?", "%#{firstname}%") unless firstname.blank?
      @clients = @clients.where("last_name like ?", "%#{lastname}%") unless lastname.blank?
    end
    @clients = @clients.order(id: :desc).page params[:page]
  end

  def book_showing
    name = params[:name]
    email = params[:email]
    @bookings = BookShowing.all
    if name || email
      @bookings = @bookings.where("name like ?", "%#{name}%") unless name.blank?
      @bookings = @bookings.where("email like ?", "%#{email}%") unless email.blank?
    end
    @bookings = @bookings.order(id: :desc).page params[:page]
  end

end
