class Api::V1::AuthController < Api::V1::BaseController 
  before_action :require_token_key!, :only => :logout
  before_action :verify_devise_access!, :only => :login
  def login
    @account = Account.find_by_email(params[:email] || params[:username])
    if @account && @account.valid_password?(params[:password])
      @account.generate_api_key!
    else
      @error_message = 'Account or password error'
      auth_error(@current)
    end
  end

  def logout
   @current_api_account.clear_api_key!
  end

  def register
    attrs = {
      email: params[:email] || params[:username],
      password: params[:password],
      first_name: params[:first_name],
      last_name: params[:last_name]
    }
    @account = Account.new attrs
    @account.password_confirmation ||= @account.password
    if @account.save
      @account.generate_api_key!
      @current_api_account = @account
    else
      invalid_resource!(@account)
    end
  end

  def forget_password
    account = Account.find_by_email(params[:email])
    if account
      account.send_reset_password_instructions
    else
      @error_message = "don't haved the account"
      invalid_resource!
    end
  end

  def callback
    return render 'api/errors/devise_access_error' unless params[:uid].present?
    AccountOmniauth.where(provider: 'facebook', uid: params[:uid]).first_or_initialize.tap do |auth|
      unless auth.account
        account = Account.where(email: params[:email]).first_or_initialize
        account.password ||= Devise.friendly_token[0,20]
        if account.image.blank? && account.avatar_url.blank?
          account.avatar_url ||= params[:image]
        end
        account.first_name ||= params[:first_name] # res.info.first_name
        account.last_name  ||= params[:last_name] # res.info.last_name
        account.save
        auth.update_attribute(:account, account)
        auth.save
      end
      @account = auth.account
      @account.generate_api_key!
      return render :login
    end
  end

end
