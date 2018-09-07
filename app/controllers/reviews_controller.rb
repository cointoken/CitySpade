class ReviewsController < ApplicationController
  before_action :set_review, only: [:show, :edit, :update, :destroy, :collect, :uncollect]
  before_action :authenticate_account!, only: [:edit, :update]
  before_action :new_reviews, only: [:index, :result, :show]
  before_action :require_login, only: [:collect, :uncollect]
  before_action :redirect_to_listing_url, only: [:collect, :uncollect]
  before_action :init_gon, only: [:new, :edit]
  before_action :check_reviews, only: :show
  before_action :only_allow_xhr, only: [:nearby_venues, :related_apartments]
  skip_before_action :verify_authenticity_token, only: [:create, :update]
  load_and_authorize_resource

  caches_action :nearby_venues, cache_path: Proc.new{|c| {lat: c.params[:lat], lng: params[:lng], v: 'yelp06'}}, expires_in: 7.days
  # cancel cache
  # caches_action :index, cache_path: Proc.new { |c| c.base_cache_params.merge({location: c.params[:location] || c.current_city.name, review_lastest_id: Review.lastest_id, last_review_id: Review.last.id})}#, expires_in: 1.hour
  def index
    #if current_account
    #@remember_reviews = Review.where(id: current_account.reputations.where(category: 'collect').map{|s| s.reputable_id}).page(params[:page])
    #end
    #@remember_reviews = [] if @remember_reviews.blank?
    @remember_reviews = Review.enable_venues.includes_account.order_by_rating(current_city).distinct_venues.page params[:page]#.limit 6
    @most_related_venues = Venue.buildings.where(political_area_id: current_city.political_city.try(:sub_ids))
      .where('overall_quality >= ?', 3).order_by_most_reviews.limit(10).to_a.sort{rand}[0..2]
    #@remember_reviews =  Review.all.order('id desc') if @remember_reviews.blank?
  end

  def result
    session[:s_r] = true
    @reviews = Review.search(params[:address], current_city, params.slice(:lat, :lng)).page params[:page]
  end

  def show
    if @review && !@venue
      return redirect_to venue_review_path(@review.venue_param)
    end
    ## get master venue for buildings and neighborhood reviews
    @venue = @venue.master_venue
    if @review.blank? && @venue
      @review = @venue.reviews.order(id: :desc).first!
    end
    #@page_description = "Ratings and opinions for #{@review.title}"
    @page_description = nil
    if params[:listing_id].present?
      @listing = Listing.find(params[:listing_id].to_i)
      @reviews = @venue.all_reviews(@review.try(:id))
        .order("(lat - #{@listing.lat}) * (lat - #{@listing.lat}) +(lng - #{@listing.lng}) * (lng - #{@listing.lng})").page params[:page]
    else
      @reviews = @venue.all_reviews(@review.try(:id)).page params[:page]
    end
    gon.local = {lat: @venue.lat || @review.lat, lng: @venue.lng || @review.lng}
    gon.ajax_urls ||= []
    gon.ajax_urls << related_apartments_review_path(@review, format: :js)
    unless @venue.building?
      render 'neighborhood_show'
    else
      gon.ajax_urls << nearby_venues_reviews_path(lat: @venue.lat.round(6), lng: @venue.lng.round(6), format: :js)
    end
  end

  def nearby_venues
    # @listing = Listing.find params[:id]
    @venue_category_order = ['grocery', 'laundry', 'restaurant']
    # @venues = FsAPI.multi_explore(@venue_category_order.join('|'), ll: params[:ll])
    @venues = YelpAPI.multi_search(@venue_category_order.join('|'), lat: params[:lat], lng: params[:lng], limit_num: 4)
    respond_to do |format|
      format.js
    end
  end

  def related_apartments
    @review_type = Review.find(params[:id]).review_type
    @related_apartments = Review.find(params[:id]).relative_listings
    respond_to do |format|
      format.js
    end
  end

  def new
    if params[:from] == 'index'
      return render :review_option
    end
    if params[:review_id]
      tmp = Review.find_by_id(params[:review_id]) if params[:review_id].present?
      if tmp
        @review = Review.new address: tmp.address, city: tmp.city,
          state: tmp.state, building_name: tmp.building_name, cross_street: tmp.cross_street
      end
    end
    @review ||= Review.new
    @review.token = account_token
    @photo = @review.photos.build
    @uploaded_photos = Photo.where(review_token: account_token, imageable_id: nil).where('created_at > ?', Time.now - 1.day)
  end

  def edit
    @uploaded_photos = @review.photos
    @photo = @review.photos.build
  end

  def create
    if check_rating_stars
      respond_to do |format|
        format.html { render action: 'new' }
        format.js { render 'error_msg.js.erb' }
      end
    else
      Review.where(token: account_token).where("account_id is null or status = ?", 0)
        .where('created_at > ?', Time.now - 1.hour).destroy_all
      if current_account
        @review = current_account.reviews.build(review_params.merge(ip: request.remote_ip))
      else
        @review = Review.new(review_params.merge(ip: request.remote_ip))
      end
      @review.token ||= account_token
      photo_ids = params[:photo_ids]
      if photo_ids.present?
        photo_ids.split(',').each do |id|
          @review.photos << Photo.find(id) if id.present?
        end
      end
      respond_to do |format|
        if @review.save
          session[:review_id] = @review.id
          session[:redirect_to] = venue_review_path(@review.venue_param)
          if current_account && params[:review_on_facebook]
            current_account.post_review(@review, review_url(@review))
          end
          @review.collect_by(current_account)
          @review.update_column(:status, false) if @review.account.blank?
          format.html { redirect_to venue_review_path(@review.venue_param), notice: 'Review was successfully created.' }
          format.json { render action: 'show', status: :created, location: @review }
          format.js
        else
          format.html { render action: 'new' }
          format.json { render json: @review.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @review.update(review_params)
        if request.xhr? && review_params[:unit]
          return render nothing: true
        end
        ## for old place input
        if review_params[:review_places_attributes]
          place_ids = review_params[:review_places_attributes].map{|s| s['id']}
        else
          place_ids = []
        end
        place_ids.reject!(&:blank?)
        if place_ids.present?
          @review.review_places.where("id not in (#{place_ids.join(',')})").destroy_all
        else
          @review.review_places.destroy_all
        end
        #photo_ids = params[:photo_ids]
        #if photo_ids.present?
        #photo_ids.split(',').each do |id|
        #@review.photos << Photo.find(id) if id.present?
        #end
        #end
        format.html { redirect_to venue_review_path(@review.venue_param), notice: 'Review was successfully updated.' }
        format.json { head :no_content }
        format.js
      else
        format.html { render action: 'edit' }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @review.set_expired
    respond_to do |format|
      if @review.venue.reviews.blank?
        format.html { redirect_to reviews_url }
      else
        format.html { redirect_to venue_url(@review.venue_param.slice(:review_type, :permalink)) }
      end
      format.json { head :no_content }
    end
  end

  def collect
    @review.collect_by(current_account)
    if params[:from] == 'index'
      collect_num = @review.venue.collect_num
    else
      collect_num = @review.reload.collect_num
    end
    render json: {collect_num: collect_num}
  end

  def uncollect
    @review.uncollect_by(current_account)
    if params[:from] == 'index'
      collect_num = @review.venue.collect_num
    else
      collect_num = @review.reload.collect_num
    end
    render json: {collect_num: collect_num}
  end

  def photos
    if params[:review_id].present?
      review = Review.find params[:review_id]
      photos = review.photos
    else
      photos = Photo.where(review_token: account_token, imageable_id: nil, imageable_type: 'Review').where('created_at > ?', Time.now - 1.day)
    end
    @photos_json = photos.map{|s| {small_url: s.image.small.url, delete_url: photo_path(s, review_token: s.review_token), id: s.id}}.to_json
  end

  private
  def set_review
    @review = Review.unscoped.find(params[:id]) if params[:id]
    if params[:review_type] && params[:permalink]
      if @review
        @venue = Venue.where(region_type: params[:review_type].classify).where(permalink: params[:permalink]).first
      else
        @venue = Venue.where(region_type: params[:review_type].classify).where(permalink: params[:permalink]).first!
      end
    end
  end

  def review_params
    params.require(:review).permit(:address, :building_name, :city, :state, :review_type,:token, :display_name,
                                   :cross_street, :ground, :quietness, :safety, :convenience, :things_to_do,
                                   :building, :management, :comment, :overall_quality, :unit,
                                   :review_places_attributes => ReviewPlace.attribute_names
                                  )
  end

  def new_reviews
    @new_reviews = Review.enable_venues.includes_account.order('id desc').limit(15)
  end

  def init_gon
    gon.ajax_urls ||= []
    if params[:id]
      gon.ajax_urls << photos_reviews_path(review_id: params[:id])
    else
      gon.ajax_urls << photos_reviews_path
    end
    @tmpl_name = 'tmpls/review_place'
  end

  def redirect_to_listing_url
    unless request.xhr?
      redirect_to @review
      return
    end
  end

  def check_reviews
    # return redirect_to @review if params[:id] != @review.to_param
    if current_account && session[:review_id]
      reviews = Review.unscoped.where(token: account_token, account_id: nil).where(id: session[:review_id]).where('created_at > ?', Time.now - 1.hour)
      reviews.update_all(account_id: current_account.id, status: 1)
      ## update ratings
      @venue.set_ratings true if @venue
      reviews.each{|s| s.reset_venue_ratings true if !@venue || @venue.id != s.venue_id}

      reviews.each{|s| s.collect_by(current_account)}
      Review.lastest_id = Time.now.to_i
      session[:review_id] = nil
      session[:redirect_to] = nil
      session[:review_token]  = nil
    end
  end

  def check_rating_stars
    if @review.review_type == 0
      @review.overall_quality.nil? || @review.building.nil? || @review.management.nil? || @review.safety.nil? || @review.convenience.nil? || @review.things_to_do.nil?
    elsif @review.review_type == 1
      @review.overall_quality.nil? || @review.ground.nil? || @review.quietness.nil? || @review.safety.nil? || @review.convenience.nil? || @review.things_to_do.nil?
    end
  end
end
