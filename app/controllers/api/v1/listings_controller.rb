class Api::V1::ListingsController < Api::V1::BaseController 
  before_action :require_token_key!, only: [:collect, :uncollect]
  before_action :set_listing, only: [:collect, :uncollect]
  
  def index
    @listings = search_listings
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
    listings = listings.where(political_area_id: current_area.sub_ids)
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
        b = :display_beds if b == :beds
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
    if params[:limit]
      listings = listings.limit params[:limit]
    end
    listings.order('listings.place_flag desc,id desc')
  end
end
