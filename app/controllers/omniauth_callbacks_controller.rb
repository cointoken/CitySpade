class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @account = AccountOmniauth.find_omniauth_auth(request.env["omniauth.auth"], current_account)

    if @account
      sign_in_and_redirect @account, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_account_registration_url
    end
  end
end
