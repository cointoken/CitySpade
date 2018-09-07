class Api::VBase::AccountController < Api::VBase::BaseController 
  before_action :require_token_key!
  def savinglists
    @listings = @current_api_account.reputable_listings
    render 'api/v_base/listings/index'
  end
end
