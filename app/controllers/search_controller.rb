class SearchController < ApplicationController
  before_action :valid_account_for_search, :only => [:index]
  before_action :check_search_url, :only => :index
  # after_action :process_worker, only: :index
  after_action :save_search_record, only: :index, unless: ->  { @exception_flag}
  def index
    session[:s_r] = nil
    opt = params.dup
    opt[:address] = opt.delete :listing_address
    @expection_flag = false
    @listings = Listing.custom_search(current_area, opt)#.page(params[:page]).per(listing_per_num)
    gon.search = {current_input_value: params[:listing_address]}
    if @listings.count == 0
      @dont_match_flag = true
      if params[:page].present? || params[:use_page]
        rand_tmp = session[:rand_tmp] || rand.round(6)
      else
        rand_tmp = session[:rand_tmp] = rand.round(6)
      end
      params[:use_page] = true
      @listings = Listing.where(flag: session[:listing_flag]).enables.all_listings_of_area(current_area)
      # begin  custom no fee order
      no_fees = @listings.where(no_fee: true).order('listing_image_id is null').order(is_full_address: :desc).order(id: :desc).limit(4)
      if no_fees.present?
        @listings = @listings.order("listings.id in (#{no_fees.map(&:id).join(',')}) desc")
      end
      @listings = @listings.default_order
      if no_fees.present?
        max_listing_id = @listings.where(no_fee: false).order(id: :desc).first.id
        no_fee_id = no_fees.first.id
        tmp_id = 0
        if no_fee_id > max_listing_id
          tmp_id = no_fee_id - max_listing_id
        end
        @listings = @listings.order("(listings.id - #{tmp_id} + listings.no_fee * (listings.id % 14) / 14 * (#{max_listing_id} - listings.id)) desc")
      end
      @listings = @listings.page(params[:page]).per(listing_per_num)
      # end no fees order
    end
    last_page = SearchHelper.check_page_no(params[:page], @listings, listing_per_num)
    if params[:page].to_i > last_page
      @exception_flag = true
      render file: "#{Rails.root}/public/404",layout: false, status: 404
    else
      @listings_total_count = @listings.count
      featured_listings = @listings.where(featured: true)
      if featured_listings.any?
        sorted_listings = sort_featured_two_per_page(@listings.where(featured: false), featured_listings)
        @listings = Kaminari.paginate_array(sorted_listings, total_count: @listings_total_count).page(params[:page]).per(listing_per_num)
      else
        @listings = @listings.page(params[:page]).per(listing_per_num)
      end
    @for_sales_or_rentals_count = Listing.where(flag: session[:listing_flag]).enables.all_listings_of_area(current_area).count
    end 
  end

  def sort_featured_two_per_page(listings, featured_listings)
    sorted = Array.new
    while featured_listings.size > 0
      sorted << featured_listings.to_a.shift(2)
      sorted.flatten
      sorted << listings.to_a.shift(12)
      sorted.flatten
    end
    sorted << listings.to_a
    sorted.flatten
  end

  def autocomplete
    result = []
    if params[:query].present? && params[:query].strip =~ /^\D/
      result = current_area.sub_areas(include_self: true).where("second_name is null and (short_name like :q or long_name like :q)", q: "#{params[:query]}%").order(id: :asc).map{ |area|
        {name: area.long_name, parent: area.borough.long_name, data: area.id, value: area.long_name}
      }.uniq{|s| s[:name]}
    end
    # if result.present?
    render json: {suggestions: result}
    # else
    #  autocomplete_for_google
    # end
  end

  def set_current_area
    if params[:current_area]
      @current_area = PoliticalArea.find_city(params[:current_area])
      session[:current_area_id] = @current_area.id
    end
    render json: nil
  end

  def map
    if params[:flag].blank?
      if session[:listing_flag].blank? || session[:listing_flag].to_s != '0'
        redirect_to search_map_flag_path(params.merge(flag: :rentals))
      else
        redirect_to search_map_flag_path(params.merge(flag: :sales))
      end
    end
    gon.search_map = true
  end

  def open_houses
    open_houses = OpenHouse.all
    if params[:date].present?
      date = Date.parse params[:date]
      open_houses = open_houses.where("open_date = ? or (`loop` = 1 and next_days = 7 and DAYOFWEEK(open_date) = ?)",
                                      date, date.wday + 1)
      params[:date] = date.to_s(:db)
      open_houses = open_houses.order("open_date = '#{params[:date]}' desc").order("(DAYOFWEEK(open_date) = #{date.wday + 1} and `loop` <> 1) desc")
    else
      open_houses = open_houses.order("open_date = '#{Date.today}' or open_date = '#{Date.today + 1.day}' desc").order("(DAYOFWEEK(open_date) = #{Time.now.wday + 1} and `loop` <> 1) desc")

    end
    open_house_ids = open_houses.order("(DATEDIFF('#{Date.today}', open_date) > -5 and DATEDIFF('#{Date.today}', open_date) < 1) desc")
      .order(loop: :desc).order(:open_date).distinct(:listing_id).pluck(:listing_id)
    @listings = Listing.enables.rentals.where(id: open_house_ids)
    if open_house_ids.present?
      @listings = @listings.order("field(id, #{open_house_ids.join(',')})")
    end
    if params[:sort].present?
      area_ids = PoliticalArea.nyc.sub_areas.where(long_name: params[:sort]).map{|s| s.sub_ids(include_self: true)}
      @listings = @listings.where(political_area_id: area_ids)
    else
      @listings = @listings.where(political_area_id: PoliticalArea.nyc.sub_ids(include_self: true))
    end
    @listings = @listings.page(params[:page]).per(18)
  end

  private
  def valid_account_for_search
    if ['price', 'transport'].include?(params[:sort]) && !current_account
      if request.xhr?
        # render js: "window.location.href='#{new_session_path(resource_name)}'"
        #else
        render 'shared/login', loyout: false, status: 422
      else
        redirect_to new_account_session_path, alert: 'Need to login to use this feature for sort by rating'
      end
    end unless mobile?
  end

  def process_worker
    if @listings && Time.now < Time.mktime(2014, 5, 24) + 40.day
      @listings.each do |listing|
        ListingWorker.perform_async(listing.id)
      end
    end
  end

  def save_search_record
    #return if params[:title].blank?
    return if spider_access?
    hash = params.dup
    hash = hash.slice(:title, :current_area, :beds, :baths, :flag, :price_from, :price_to)
    if params[:neighborhoods].present?
      hash[:title] = [params[:neighborhoods].select!{|s| s.present?}, params[:listing_address]].select{|s| s.present?}.join(' + ')
    end
    hash[:min_price], hash[:max_price] = hash.delete(:price_from), hash.delete(:price_to)
    hash[:political_results_count] = @for_sales_or_rentals_count
    hash[:results_count] = @listings.total_count
    hash[:session_id] = session.id
    hash[:account_id] = current_account.try(:id)
    SearchRecordWorker.perform_async(hash, params[:page].blank?)
  end

  def check_search_url
    if params[:current_area].blank? || params[:current_area] != current_area.long_name.to_url
      params[:current_area] = current_area.long_name.to_url
      params[:flag] ||= Settings.listing_flags.rental
      return redirect_to area_search_path(params)
    end
    get_rental_or_sale_id

    #if params[:flag].blank? && session[:listing_flag] == 0
    #params[:flag] = 'sales'# if session[:listing_flag] == 0
    #else
    #params[:flag] ||= 'rentals'
    #end
    # params[:flag] ||= session[:listing_flag]
    params[:baths].delete_if{|s| s.blank?} if params[:baths].present? && params[:baths].is_a?(Array)
    params[:beds].delete_if{|s| s.blank?} if params[:beds].present? && params[:beds].is_a?(Array)
  end

  def autocomplete_for_google
    json = Google::Place.autocomplete(params[:query] || params[:q], {language: :en, location: "#{current_area.lat},#{current_area.lng}"})
    render json: {suggestions: json[:places].map{|pl| pls = pl[:name].split(',')
                                                 name = pls.size > 3 ? pls[0...-2].join(',') : pl[:name]
                                                 # parent = pls.size > 3 ?  "#{pls[-3]}, #{pls[-2]}" : ''
                                                 parent = (pls.size > 2 ? pls[-2] : pls[-1])
                                                 state = pls[-2].strip
                                                 {name: name, parent: parent,value: name, data: Time.now.to_i, state: state
                                                 }}.select{|s| s[:state] == current_area.state.short_name}}

  end

  def listing_per_num
    mobile? ? 25 : Listing.default_per_page
  end
end
