class Admin::ContactEmailsController < Admin::BaseController
  before_filter :require_admin
  respond_to :html, :json

  def index
    @contacts = ContactEmail.all
  end

  def show
    @contact = ContactEmail.find params[:id]
  end

  def new
    @contact = ContactEmail.new
  end

  def edit
    @contact = ContactEmail.find params[:id]
  end

  def update
    @contact = ContactEmail.find params[:id]
    @contact.update_attributes params[:contact_email]
    respond_with @contact
  end

  private

  def contact_email_params
    params.require(:contact_email).permit(:email, :building, :name)
  end

end
