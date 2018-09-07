class Api::V1::AccountController < Api::V1::BaseController 
  before_action :require_token_key!
  def savinglists
    @listings = @current_api_account.reputable_listings
    render 'api/v1/listings/index'
  end
end
