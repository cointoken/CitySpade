class Api::VBase::ListingsController < Api::VBase::BaseController 
  before_action :require_token_key!, only: [:collect, :uncollect]
  before_action :set_listing, only: [:collect, :uncollect]
  
  def index
    @listings = search_listings.select(*select_columns)
  end

  def cities
    @cities = Settings.cities.map{|city| PoliticalArea.send(city.first)}
  end

  def simple
    @listings = search_listings.select(:id, :lat, :lng)
  end

  def show
    @listing = Listing.find params[:id]
  end

  def collect
    obj = Reputation.where(reputable: @listing, category: 'collect', account: @current_api_account).first_or_create
    success_create(obj)
  end

  def uncollect
    reputable = Reputation.where(reputable: @listing, category: 'collect', account: @current_api_account)
    if reputable.present?
      reputable.destroy_all
    end 
    success_destroy
  end
  def set_listing
    @listing = Listing.find params[:id]
  end

  private
  def search_listings
    listings = Listing.enables
    if params[:rent]
      listings = listings.where(flag: params[:rent])
    end
    listings = listings.where(political_area_id: current_area.sub_ids) if current_area
    [:lat, :lng].each do |l|
      if params["northeast#{l}"]
        listings = listings.where("listings.#{l} <=? ", params["northeast#{l}"])
      end
      if params["southwest#{l}"]
        listings = listings.where("listings.#{l} >=? ", params["southwest#{l}"])
      end
    end
    [:beds, :baths].each do |b|
      if params[b]
        if params[b] =~ /\+$/ || params[b] =~ /\s$/
          s = '>='
        elsif params[b] =~ /\-$/
          s = '<='
        else
          s = '='
        end
        listings = listings.where("listings.#{b} #{s} ?", params[b].to_f)
      end
    end
    if params[:lowprice]
      listings = listings.where('listings.price >= ?', params[:lowprice])
    end
    if params[:highprice]
      listings = listings.where('listings.price <= ?', params[:highprice])
    end
    [:listing_type, :zipcode].each do |l|
      if params[l]
        listings = listings.where(l => params[l])
      end
    end
    listings = listings.limit params[:limit]
    # listings = listings.select(*select_columns)
    listings = listings.order('listings.listing_image_id is null, listings.is_full_address desc')
    if params[:page] && params[:per]
      listings = listings.page(params[:page]).per(params[:per])
    end
    if params[:order]
      hash = {'cost-efficiency' => 'score_price', 'transportation' => 'score_transport'}
      ors = params[:order].split('.') 
      col = hash[ors.first.downcase] || ors.first.downcase
      sort_name = ors[1] || :asc
      listings = listings.order(col => sort_name.to_sym)
    end
    listings = listings.order(id: :desc)
    listings
  end

  def select_columns
    @select_columns ||= [:id, :title, :price, :baths, :beds, :lat, :lng, :zipcode,:score_price, :score_transport, :unit,
                         :image_base_url, :listing_image_id, :image_sizes, :flag, :is_full_address, :mls_info_id, :street_address]# .concat(listing_params[:index]).uniq
  end
end
