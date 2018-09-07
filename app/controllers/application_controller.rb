class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  force_ssl if: :use_ssl?
  #before_filter :check_link
  before_filter :set_locale
  helper_method :current_area, :resource_name, :resource, :devise_mapping, :current_city,
    :mobile?, :page_status_class, :created_obj?, :iphone?, :spider_access?, :search_neighborhood_name
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :hook_rack_mini_profiler
  before_action :prepare_for_mobile
  before_action :init_js_args
  # before_action :check_download_url
  before_action :set_meta
  #before_action :default_url_options
  after_action :update_page_view, only: :show, if: ->(res) { !res.request.xhr?}
  #before_action do
  #  resource = controller_name.singularize.to_sym
  #  method = "#{resource}_params"
  #  params[resource] &&= send(method) if respond_to?(method, true)
  #end

  def default_url_options #opt={}
    if Rails.env.production? || Rails.env.staging?
      super.merge :protocol => 'https://'
    else
      super
    end
    #if I18n.locale.nil?
    super.merge :locale => I18n.locale
    #else
    #super.merge :locale => extract_locale_from_accept_language_header
    #end
  end

  def init_js_args
    gon.logined = current_account.present?
    gon.mobiled = mobile?
    if params[:id]
      gon.obj_id = params[:id]
    end
    gon.obj_name = controller_name
    gon.created_obj = created_obj?
    #gon.page_protected = page_status_class == 'body-protected'
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :first_name << :last_name
    devise_parameter_sanitizer.for(:account_update) << :first_name << :last_name << :image << [:first_phone, :last_phone]
  end
  protected :configure_permitted_parameters

  MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
    'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
    'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
    'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
    'webos|amoi|novarra|cdm|alcatel|pocket|iphone|mobileexplorer|mobile'

  SPIDER_ACCESS_USER_AGENTS = 'googlebot|bingbot|iaskspider|msnbot|baiduspider'

  def mobile?
    return true if subdomain == 'm'
    agent_str = request.user_agent.to_s.downcase
    return false if agent_str =~ /ipad/
    !!(agent_str =~ Regexp.new(MOBILE_USER_AGENTS))
  end

  def iphone?
    false
    #request.user_agent.to_s.downcase =~ /iphone/
  end

  #def search_neighborhood_name
  #  if params[:neighborhood]
  #    @search_neighborhood_name ||= current_area.sub_areas.find_by_permalink(params[:neighborhood]).try(:long_name)
  #  end
  #end

  def require_login
    unless current_account
      if request.xhr?
        return respond_to do |format|
          format.js { render 'shared/login', layout: false, status: 401}
        end
      else
        if ['collect', 'uncollect'].include? action_name
          session[:redirect_to] = request.referer
        end
        authenticate_account!
      end
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    alert_info = "You don't have permission to do it!"
    if request.env["HTTP_REFERER"]
      redirect_to :back, :alert => alert_info
    else
      redirect_to '/', :alert => alert_info
    end
  end

  def get_rental_or_sale_id
    if params[:flag] =~ /^\d$/
      session[:listing_flag] =  params[:flag]
    else
      session[:listing_flag] = (params[:flag] ? (params[:flag].starts_with?('sale') ? 0 : 1) : (session[:listing_flag] || 1))
    end
    session[:listing_flag]
  end

  def resource_name
    :account
  end

  def resource
    @resource ||= Account.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:account]
  end

  def current_areas
    PoliticalArea.all_cities
  end

  def after_sign_out_path_for(account)
    request.referrer
  end

  def after_sign_up_path_for(account)
    edit_account_registration_path
  end

  def after_sign_in_path_for(resource_or_scope)
    session[:redirect_to] || request.env['omniauth.origin'] || stored_location_for(resource_or_scope) || search_path
  end
  def current_user
    current_account
  end

  def set_client_token
    session[:client_token] ||= SecureRandom.hex(30)
  end

  def refresh_client_token
    session[:client_token] = SecureRandom.hex(30)
  end


  def current_area
    @current_area ||= begin
                        area = if params[:current_area]
                                 PoliticalArea.where(target: 'locality', long_name: params[:current_area].gsub('-',' ')).first ||
                                   PoliticalArea.default_area
                               elsif session[:current_area_id]
                                 PoliticalArea.find session[:current_area_id]
                               else
                                 if geoip_city
                                   case geoip_city.state
                                   when 'PA'
                                     PoliticalArea.philadelphia
                                   when 'MA'
                                     PoliticalArea.boston
                                   else
                                     PoliticalArea.default_area
                                   end
                                 else
                                   PoliticalArea.default_area
                                 end
                               end
                        session[:current_area_id] = area.id
                        area
                      end
  end

  def geoip_city
    @geoip_city ||= begin
                      ip = request.headers['X-Real-IP'] || request.remote_ip
                      if ip =~ /^127/
                        ip = params[:ip]
                      end
                      geoip = Geokit::Geocoders::MaxmindGeocoder::geocode(ip)
                      geoip = Geokit::Geocoders::IPApiGeocoder.geocode ip if !geoip.success? || (geoip.city.blank? || geoip.country_code != 'US')
                      City.where(name: geoip.city, long_state: geoip.state, country: 'US').first
                    end
  end

  def current_city
    @current_city ||= session[:current_city_id] && City.find(session[:current_city_id])
    if params[:location]
      if @current_city.blank? || !params[:location].downcase.include?(@current_city.name.downcase)
        city_name, state_name = params[:location].split(',').map(&:strip)
        if state_name && state_name.split(/\s/).size > 1
          state_name = state_name.split(/\s/).map(&:first).reject(&:blank?).join
        end
        @current_city = City.where(name: city_name)
        @current_city = @current_city.where(state: state_name) if state_name
        @current_city = @current_city.order(hot: :desc).first
      end
      #elsif current_area
      #@current_city = City.where(name: current_area.long_name, country: 'US').order(hot: :desc).first
    end
    @current_city ||= geoip_city || City.where(name: current_area.long_name, country: 'US').order(hot: :desc).first
    @current_city ||= City.where(name: 'New York', state: 'NY', country: 'US').first
    session[:current_city_id] = @current_city.id
    @current_city
  end

  def set_current_area
    if params[:current_area].present?
      @current_area = PoliticalArea.find_city(params[:current_area].gsub('-', ' '))
      session[:current_area_id] = @current_area.id
    end
  end

  def created_obj?(obj_name = nil)
    if current_account
      if current_account.respond_to?(obj_name || controller_name) && current_account.send(obj_name || controller_name).reload.present?
        true
      else
        false
      end
    else
      false
    end
  end

  def page_status_class
    if controller_name == 'reviews' && action_name == 'show' && !mobile?
      if !created_obj?
        #'body-protected'
      end
    end
  end

  def base_cache_params
    @base_cache_params ||= {release_id: Rails.root.basename.to_s, current_account_id: current_account.try(:cache_id)}
  end

  private
  def prepare_for_mobile
    if mobile? && File.exist?(Rails.root.join('app', 'views', controller_name, "#{action_name}.mobile.slim"))
      if request.format.symbol == :html
        request.formats = [:mobile, :html]
      else
        request.formats = [request.format.symbol, :mobile, :html]
      end
    end
  end
  def subdomain
    request.subdomain.present? && request.subdomain.downcase
  end
  def check_download_url
    return unless iphone?
    if params[:from].present? && params[:from].downcase == 'download'
      cookies[:iphone_access] = { value: true, expires: 14.days.from_now }
    end
    unless cookies[:iphone_access].to_s == 'true'
      session[:redirect_to] = url_for(params.merge(from: :download))
      return redirect_to download_path(redirect_to: session[:redirect_to])
    end
  end

  def spider_access?
    !!(request.user_agent.downcase =~ Regexp.new(SPIDER_ACCESS_USER_AGENTS))
  end
  def account_token
    session[:account_token] ||= Digest::MD5.hexdigest((current_account.try(:id) || session.id).to_s + rand(100).to_s)[0..20]
  end

  def update_page_view
    UpdatePageViewWorker.perform_async(params[:id], controller_name, current_account.try(:id)) if params[:id]
  end

  def only_allow_xhr
    return render nothing: true unless request.xhr?
  end

  def hook_rack_mini_profiler
    if current_account && current_account.admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  def set_meta
    case controller_name
    when 'home'
      if current_area.long_name == 'New York'
        city_name = 'NYC'
      else
        city_name = current_area.long_name
      end
      @page_title = 'CitySpade: Apartments for Rent, Building and Neighborhood Reviews, Sublets and Rommates'
      @page_description = 'Make smarter rental decisions through our building and neighborhood reviews. Let CitySpade connect you with your next dream apartment.'
      @page_keywords = "CitySpade, apartments, buildings, neighborhoods, reviews, NO FEE apartments, apartments for rent, #{city_name} apartments, sublets, room, roommates,
        纽约, 公寓, 免中介费, 纽约租房中介, 公寓出租, 纽约住房, 纽约租房, 评价"
    when 'search'
      if action_name == 'index'
        title = params[:title] || search_neighborhood_name
        if title.present?
          @page_title = "Search apartments for #{params[:flag] || Settings.listing_flags.rental}: #{title}"
          @page_description = "Search apartments for #{params[:flag] || Settings.listing_flags.rental} #{title} in New York City"
        else
          @page_title = "Search apartments for #{params[:flag] || Settings.listing_flags.rental}"
          @page_description = "Search apartments for #{params[:flag] || Settings.listing_flags.rental} in New York City"
        end
        @page_description << " | CitySpade"
        @page_keywords = "CitySpade, search, listing, #{(params[:flag] || Settings.listing_flags.rental).sub(/s$/, '')}"
      elsif action_name == 'open_houses'
        @page_title = "Open Houses in New York City"
        @page_description = "See all available open house schedules for rental apartments in New York City. Prepare best for your apartment search."
      end
    when 'listings'
      if action_name == 'neighborhoods'
        if current_area.long_name == 'New York'
          city_name = 'New York City'
        else
          city_name = current_area.long_name
        end
        @page_title = "Neighborhoods for #{city_name}"
        @page_description = 'Complete neighborhood list in New York City, Philadelphia and Boston'
        @page_keywords = 'CitySpade, neighborhood, NYC, New York City, Philadelphia, Boston'
      end
    when 'pages'
      if action_name == 'show'
        case params[:id]
        when 'terms'
          @page_title = 'Terms of Use'
        when 'privacy'
          @page_title = 'Privacy Policy'
        when 'contact'
          @page_title = 'Contact Us'
        when 'about'
          @page_title = 'About Us'
        when 'support'
          @page_title = 'Frequently Asked Questions'
        end
        @page_description = 'Make smarter rental decisions through our building and neighborhood reviews. CitySpade is here to help you with your apartment search in New York City.'
        @page_keywords = 'CitySpade, New York, NYC, apartment, rent, About Us, Contact, Terms of Use, Faq, Support'
      end
    when 'reviews'
      case action_name
      when 'index','result'
        if params[:address].present?
          @page_title = "Search Building and Neighborhood Reviews in #{current_city.polupar_name}: #{params[:address]}"
        elsif action_name == 'result'
          @page_title = "Search Building and Neighborhood Reviews in #{current_city.polupar_name}"
        else
          @page_title = 'Building and Neighborhood Reviews'
        end
        if params[:page]
          @page_title << ", Page #{params[:page]}"
        end
        @page_description = 'Ratings and reviews for many buildings, apartments and neighborhoods in New York City.'
      end
    when 'blogs'
      if action_name == 'index'
        @page_title = 'Blog | CitySpade'
      end
    when 'contacts'
      @page_title = 'Contact Us | CitySpade'
    when 'list_with_us'
      @page_title = 'List with Us | CitySpade'
    when 'flashsales'
      @page_description = 'Recieve a move-in bonus on select no-fee apartments in New York City. | CitySpade'
      @page_keyboards = 'CitySpade, no fee, apartment, rent, bonus, dailydeals, New York, NYC, studio, bed, bath, studio'
    when 'room_search', 'roommates','rooms'
      if action_name == 'index'
        @page_description = 'CitySpade provides a platform to find suitable roommates and rooms for sublet in New York City.'
      end
      @page_keywords = 'CitySpade, New York City, NYC, rooms, sublet, roommates, rent, room offer, apartment'
    else
      @page_title ||= 'CitySpade: Apartments for Rent, Building and Neighborhood Reviews, Sublets and Roommates'
      @page_description ||= 'Make smarter rental decisions through our building and neighborhood reviews. CitySpade is here to help you with your apartment search in New York City.'
      @page_keywords ||= 'CitySpade, apartments, buildings, neighborhoods, reviews, NO FEE apartments, apartments for rent, NYC apartments,
        纽约, 公寓, 免中介费, 纽约租房中介, 公寓出租, 纽约住房, 纽约租房, 评价'
    end
    if @page_title
      if params[:page]
        @page_title << ", Page #{params[:page]}"
      end
      @page_title << " | CitySpade"
    end
  end

  def use_ssl?
    #Rails.env.production? || Rails.env.staging?
    Rails.env.production?
  end

  def binding_review(account=nil)
    account ||= current_account
    if session[:redirect_to] && session[:redirect_to].include?("reviews") && session[:review_id]
      Review.unscoped.where(id: session[:review_id]).update_all account_id: account.id, status: 1
      #Review.where(token: account_token).where("account_id is null").update_all account_id: resource.id
    end
  end

  def set_locale
    if params[:locale].present?
      I18n.locale = params[:locale]
    else
      I18n.locale = extract_locale_from_accept_language_header
    end
  end

  def extract_locale_from_accept_language_header
    if !request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      case request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      when 'en'
        'en'
      when 'ko'
        'kr'
      when 'ch','zh'
        'ch'
      else
        'en'
      end
    else
      'en'
    end
  end

  # Code for iPad/GoPro promo modal
  #
  # helper_method :has_ads?
  # before_action :check_has_ads
  #
  # def check_has_ads
  #   gon.has_ads = !Review.created_by_ip?(request.remote_ip) && !cookies[:ads_shown]
  #   gon.ads = {ele: '#ads-gift', interval: 4000}
  # end
  #
  # def has_ads?
  #   !!gon.has_ads
  # end
end
