class SessionsController < Devise::SessionsController
  skip_before_filter :verify_authenticity_token, :only => :create
  def create
    if request.xhr?
      resource = Account.where(email: params[:account][:email]).first
      binding_review resource
      if resource
        if resource.valid_password?(params[:account][:password])
          # resource = warden.authenticate!(auth_options)
          sign_in(resource_name, resource)
          return render  :json => {success: true, redirect_to: session[:redirect_to]}, layout: false
        end
      end
      return render :json => {success: false}
    else
      super
    end
  end
end
