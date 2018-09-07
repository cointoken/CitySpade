class Api::BaseController < ActionController::Base
  helper_method :current_api_account
  before_action :set_json_format
  def current_api_account
    @current_api_account ||= Account.find_by_api_key(token_key) if token_key.present?
  end
  def token_key
    @token_key ||= request.headers["X-CitySpade-Token"] || params[:token]
  end
  def require_token_key!
    unless current_api_account
      token_error
      return false
    end
  end
  def auth_error(account)
    @resource = account
    @error_message ||= 'account Unauthorized'
    render 'api/errors/auth_error', status: 401
  end
  def token_error
    @error_message ||= 'token error'
    render 'api/errors/token_error', status: 401
  end
  def invalid_resource!(resource=nil)
    @resource = resource
    @error_message ||= @resource.errors.full_messages  if @resource
    render 'api/errors/invalid_resource', status: 422
  end
  def success_create(resource)
    @resource = resource
    render partial: 'api/shared/create'
  end
  def success_destroy(resource=nil)
    @resource = resource
    render partial: 'api/shared/destroy'
  end
  def verify_devise_access!
    str = [params[:username], params[:password], params[:client_uuid], 'CitySpade']
    str = str.sort.join
    hex = Digest::SHA1.hexdigest str
    unless hex == params[:client_secret]
      @error_message ||= 'devise access error'
      render 'api/errors/devise_access_error' ,status: 422
      return false
    end
  end
  # use in listings search
  def current_area
    PoliticalArea.nyc
  end

  private
  def current_geoip(redo_flag = false)
    return current_city if current_city && !redo_flag
    ip = request.headers['X-Real-IP'] || request.remote_ip
    if ip =~ /^127/
      ip = params[:ip]
    end
    # geoip = Geokit::Geocoders::MaxmindGeocoder::geocode(ip)
    # geoip = Geokit::Geocoders::IPApiGeocoder.geocode ip if !geoip.success? || (geoip.city.blank? || geoip.country_code != 'US')
    @current_city = City.where(name: geoip.city, long_state: geoip.state, country: 'US').first || City.where(name: 'New York', state: 'NY', country: 'US').first
    session[:current_city_id] = @current_city.id
    @current_city
  end

  # use in reviews
  def current_city
    @current_city ||= begin
                        if session[:current_city_id]
                          City.find session[:current_city_id]
                        end
                      end
  end

  def set_json_format
    request.formats= [:json] if params[:format].blank?
  end
end
