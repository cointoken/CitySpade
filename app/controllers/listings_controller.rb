class ListingsController < ApplicationController
  # include ApplicationHelper
  # Make sure models/ability.rb allows public actions

  load_and_authorize_resource
  before_action :set_listing, only: [:show, :edit, :update, :destroy, :collect, :uncollect, :distancematrix, :contact, :fancybox_content]
  before_action :require_login, only: [:collect, :uncollect, :new]
  before_action :redirect_to_listing_url, only: [:collect, :uncollect]
  before_action :only_allow_xhr, only: [:nearby_venues, :nearby_homes, :nearby_reviews]
  after_action :process_worker, only: :show
  after_action :calculate_transit_score, only: :create
  skip_before_action :verify_authenticity_token, only: [:nearby_reviews, :nearby_homes, :nearby_venues]

  caches_action :nearby_venues, cache_path: Proc.new{|c| {lat: c.params[:lat], lng: params[:lng], v: 'yelp08'}}, expires_in: 7.days

  def index
    redirect_to search_path
  end

  def show
    gon.ajax_urls ||= []
    if @listing
      @page_keywords = "CitySpade,Listing,#{@listing.political_area.try(:long_name)},#{@listing.title}"
      gon.ajax_urls << api_geoip_outdoor_path(lat: @listing.lat, lng: @listing.lng,element_id:'#js-listing-data' , format: :js)
      gon.ajax_urls << nearby_homes_listing_path(@listing, format: :js)
      gon.ajax_urls << nearby_reviews_listing_path(@listing, format: :js)
      gon.ajax_urls << nearby_venues_listings_path(lat: @listing.lat.round(6), lng: @listing.lng.round(6), format: :js)
    end
    @reviews = Review.distinct_venues.order("abs(reviews.lat - #{@listing.lat}) + abs(reviews.lng - #{@listing.lng})").limit 5
  end

  def fancybox_content
    render layout: false
  end

  def new
   # gon.ajax_urls ||= []
    opts = {}
    if params[:current_step].blank?
      opts[:image_type] = 'Listing'
    else
      opts[:image_type] = 'Agent'
    end
    #gon.ajax_urls << photos_listings_path(opts)
    if params[:token].present?
      account = Account.find_by office_token: params[:token]
      account.become_office_account if account.present?
    end
    session[:listing_params] ||= {}
    @listing = Listing.new city_name: current_city.name, state_name: current_city.state, price: nil
    @listing_detail = @listing.build_listing_detail
  end

  def edit
    gon.ajax_urls ||= []
    opts = {}
    if params[:current_step].blank?
      opts[:image_type] = 'Listing'
    else
      opts[:image_type] = 'Agent'
    end
    if @agent.present?
      opts[:id] = @agent.id
    else
      opts[:id] = @listing.id
    end
    gon.ajax_urls << photos_listings_path(opts)
    render :edit
  end

  def create
    if params[:listing].present? || params[:agent].present?
      @listing = current_account.listings.new(listing_params.merge(never_has_url: true, flag: 1))
      if @listing.save && @listing.political_area
        _agent = Agent.where(name: current_account.name, email: current_account.email).first
        @agent = _agent.blank? ? current_account.agents.create(name: current_account.name, email: current_account.email, tel: current_account.first_phone + current_account.last_phone)
        : @agent = _agent
        opt = {listing_image_id: params[:photo_ids].split(',').first, agent_id: @agent.id}
        @listing.update_columns opt
        Photo::Listing.unscoped.where(id: params[:photo_ids].split(',')).update_all(imageable_id: @listing.id, imageable_type: 'Listing')
        if listing_params[:image_base_url].present?
          create_video_for_listing(listing_params[:image_base_url], @listing)
        end
        if listing_params[:featured]
          @listing.featured_for(listing_params[:featured].to_i)
        end
        session[:new_listing_id] = @listing.id
        redirect_to listing_path(@listing)
      else
        render :new, notice: @listing.errors.full_messages.join("\n")
      end
    else
      redirect_to new_listing_path
    end
  end

  def update
    if params[:listing].present? || params[:agent].present?
      if @listing.update_attributes(listing_params) && @listing.political_area
        _agent = Agent.where(name: current_account.name, email: current_account.email).first
        @agent = _agent.blank? ? current_account.agents.create(name: current_account.name, email: current_account.email, tel: current_account.first_phone + current_account.last_phone)
        : @agent = _agent
        if params[:photo_ids]
          opt = {listing_image_id: params[:photo_ids].split(',').first, agent_id: @agent.id}
          @listing.update_columns opt
          Photo::Listing.unscoped.where(id: params[:photo_ids].split(',')).update_all(imageable_id: @listing.id, imageable_type: 'Listing')
        end
        if listing_params[:video_url].present?
          create_video_for_listing(listing_params[:video_url], @listing)
        end
        if listing_params[:featured]
          @listing.featured_for(listing_params[:featured].to_i)
        end
        session[:edit_listing_id] = @listing.id
        redirect_to listing_path(@listing)
      else
        render :new, notice: @listing.errors.full_messages.join("\n")
      end
    else
      redirect_to listing_path
    end
  end

  def destroy
    @listing.destroy
    respond_to do |format|
      format.html { redirect_to listings_url }
      format.json { head :no_content }
    end
  end

  def collect
    if not current_account.collect? @listing
      Reputation.create({reputable: @listing,
                         category: 'collect',
                         account_id: current_account.id})
      respond_to do |format|
        format.js { render 'collect'}
      end
    else
      redirect_to action: "uncollect"
    end
  end

  def uncollect
    reputation = current_account.collected(@listing)
    if reputation.present?
      reputation.destroy
      respond_to do |format|
        format.js { render 'collect' }
      end
    else
      redirect_to action: "collect"
    end
  end

  def neighborhoods
    Neighborhood.city_by(current_area.long_name).each do |ngh|
      if ngh.borough.present?
        @neighborhoods ||= {}
        @neighborhoods[ngh.borough] ||= []
        @neighborhoods[ngh.borough] << ngh.name
      else
        @neighborhoods ||= []
        @neighborhoods[0] ||= []
        if @neighborhoods.last.size >= 20
          @neighborhoods << []
        end
        @neighborhoods[-1] << ngh.name
      end
    end
    @neighborhoods ||= []
  end

  def nearby_homes
    listing = Listing.find(params[:id])
    @nearby_homes = listing.relative_listings.limit 15
    respond_to do |format|
      format.js
    end
  end

  def nearby_reviews
    @listing = Listing.find(params[:id])
    @nearby_reviews = @listing.relative_reviews #Review.limit(3)
    respond_to do |format|
      format.js
    end
  end

  def nearby_venues
    begin
      @venue_category_order = ['grocery', 'laundry', 'parking', 'restaurant']
      @venues = YelpAPI.multi_search(@venue_category_order.join('|'), lat: params[:lat], lng: params[:lng])
      respond_to do |format|
        format.js
      end
    rescue => err
      Rails.logger.warn err.message
      render nothing: true
    end
  end

  def send_message
    @listing = Listing.find params[:listing_id]
    (@listing.agent.blank? && @listing.is_mls? && @listing.broker.try(:email).present?) ?
      @type = "broker" : @type = "agent"
    if @listing.is_flash_sale
      @type = "agent"
    end
    if request.post?
      params[:contact][:agent_id] ||= params[:agent_id]
      MailNotifyWorker.perform_async(nil, :send_message_to_agent, params[:contact])
      UpdatePageViewWorker.perform_async(params[:listing_id], 'ContactAgent', current_account.try(:id), 0)# unless request.xhr?
      exec_js = '$("#contact-email-form").fadeOut("slow", function(){$(".message-success").fadeIn("slow")});'
      exec_js << "setTimeout('window.location.href=\"#{listing_path(@listing)}\"', 4000);" if mobile?
      render js: exec_js#'$("#contact-email-form").fadeOut("slow", function(){$(".message-success").fadeIn("slow")});'
    end
  end

  def flash_email
    @listing = Listing.find params[:listing_id]
    if @listing.is_flash_sale
      agent = Agent.find_by(email: "kiran.chen@cityspade.com")
    end
    params[:contact][:agent] = agent.email
    MailNotifyWorker.perform_async(nil, :send_flash_email, params[:contact])
      UpdatePageViewWorker.perform_async(params[:listing_id], 'ContactAgent', current_account.try(:id), 0)
    redirect_to @listing, notice: "Message sent successfully"
  end

  def expire
    @listing = Listing.find params[:id]
    @listing.set_expired
    #if @listing.agent.present? && @listing.agent.email == current_account.email && !@listing.expired?
      #@listing.update_column(status: 1)
      redirect_to account_listings_path(Settings.listing_status.expired), notice: "Successfully expire the listing."
    #else
      #redirect_to account_listings_path, notice: "Fail to expire the listing."
    #end
  end

  def refresh
    @listing = Listing.find params[:id]
    to_page = (@listings.status == -1 ? Settings.listing_status.actived : Settings.listing_status.expired)
    @listing.status = 0
    if @listing.save
      redirect_to account_listings_path(Settings.listing_status.actived), notice: "Successfully refresh the listing."
    else
      redirect_to account_listings_path(to_page), notice: "Fail to refresh the listing."
    end
  end

  def photos
    if params[:image_type].blank?
      return render nothing: true
    end
    kcls = "Photo::#{params[:image_type]}".constantize
    photos = kcls.where(review_token: account_token, imageable_type: params[:image_type]).where('created_at > ?', Time.now - 1.day)
    photos = photos.where(imageable_id: params[:id]) if params[:id]
    @photos_json = photos.map{|s| {small_url: s.image.small.url, delete_url: photo_path(s, review_token: s.review_token), id: s.id}}.to_json
  end

  def create_video_for_listing(url, listing)
    if listing.images.to_s.include?('ListingImage')
      if !listing.images.select{|i| i.origin_url.include?('youtube')}.empty?
        listing.images.select{|i| i.origin_url.include?('youtube')}.last.update_attributes(origin_url: url, s3_url: url)
      else
        video = ListingImage.create(listing_id: listing.id, s3_url: listing.video_url, origin_url: url)
      end
    end
    if !listing.photos.empty? && !listing.photos.where('video_url is NOT NULL').empty?
      video = listing.photos.where('video_url is NOT NULL').first
      video.update_attributes(video_url: url)
    else
      video = Photo::Listing.create(imageable_type: "Listing", imageable_id: listing.id, video_url: url, is_top: true)
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_listing
    @listing = Listing.latlngs.accessibles.find(params[:id])
    return redirect_to @listing, status: 301 if @listing.to_param != params[:id]
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def listing_params
    params.require(:listing).permit(:title, :political_area_id, :unit, :beds, :baths, :image_base_url, :featured, :video_url,
                                    :sq_ft, :type_name, :contact_name, :contact_tel, :room_type, :available_begin_at, :no_fee,
                                    :available_end_at, :price, :zipcode, :listing_detail_attributes => [{:amenities => []},:description])
  end

  def process_worker
    if @listing && Time.now < Time.mktime(2014, 5, 24) + 14.day
      ListingWorker.perform_async(@listing.id)
    end
  end

  def calculate_transit_score
    Spider.cal_transit_score
  end

  def redirect_to_listing_url
    unless request.xhr?
      redirect_to @listing.permalink, status: 301
      return
    end
  end
end
