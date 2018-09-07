class Admin::AccountsController < Admin::BaseController
  before_filter :require_admin
  
  def show
    @account = Account.find(params[:id])
  end

  def index
    @accounts = Account.all #includes(:account_omniauths).joins(:account_omniauths).all
    @accounts = @accounts.where("first_name like ?", "%#{params[:first_name]}%") unless params[:first_name].blank?
    @accounts = @accounts.where("last_name like ?", "%#{params[:last_name]}%") unless params[:last_name].blank?
    @accounts = @accounts.where(role: params[:role]) unless params[:role].blank?
    if params[:bind_facebook] == 'true'
      @accounts = @accounts.includes(:account_omniauths).joins(:account_omniauths)
      @accounts = @accounts.where('account_omniauths.provider = ?', 'facebook').where('account_omniauths.id is not null')
    end
    if params[:sort]
      @accounts = @accounts.order("#{sort_column} #{sort_direction}")
    else
      @accounts = @accounts.order(id: :desc)
    end
    if params[:deactive] == 'true' && params[:account_id].present?
      account = Account.find params[:account_id]
      account.listings.where.not(status: 1).update_all status: 1, updated_at: Time.now
      flash.notice = 'deactived success!'
    end
    @accounts = @accounts.page(params[:page]||1).per(10)
  end

  def new
    @account = Account.new
  end

  def edit
    @account = Account.find(params[:id])
  end

  def update
    if params[:account][:password].empty?
      params[:account].delete(:password)
      params[:account].delete(:password_confirmation)
    end

    @account = Account.find(params[:id])
    if @account.update_attributes(account_params)
      redirect_to admin_account_path(@account)
    else
      render :edit
    end
  end

  def create
    @account = Account.new account_params
    if @account.save
      redirect_to admin_accounts_path
    else
      render :edit
    end
  end

  private

  def account_params
    params.require(:account).permit(:first_name, :last_name, :first_phone, :last_phone,
                                    :email, :password, :password_confirmation, :role,
                                    mail_notify_attributes: [:is_recommended])
  end
end
