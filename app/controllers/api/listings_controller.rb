class Api::ListingsController < Api::BaseController
  def index
    @listings = Listing.enables.rentals
    if params[:lat].present? && params[:lng].present?
      @listings = @listings.default_order_by_loc(params[:lat], params[:lng], 1, 0.7)
      @listings = @listings.where("abs(lat - ?) < 1 and abs(lng - ?) < 1", params[:lat], params[:lng]).limit params[:limit] || 20
    elsif params[:northeast_lat] && params[:northeast_lng] && params[:southwest_lat] && params[:southwest_lng]
      @listings = @listings.default_order_by_loc(
        (params[:northeast_lat].to_f + params[:southwest_lat].to_f) / 2,
        (params[:northeast_lng].to_f + params[:southwest_lng].to_f) / 2,
        1, 0.7
      )
      @listings = @listings.where("lat < ? and lat > ?", params[:northeast_lat], params[:southwest_lat])
      .where("lng < ? and lng > ?", params[:northeast_lng], params[:southwest_lng]).limit 50
    else
      @listings = []
    end
    render 'api/v1/listings/index'
  end
  helper_method :listing_params
  def listing_params
    @listing_param ||= {
      search: [:northeastlat, :northeastlng, :southeastlat, :southeastlng,
               :bedroom, :bathroom, :lowprice, :highprice, :rent, :listing_type, :zipcode],
               index: [:id, :title, :price, :baths, :beds, :lat, :lng, :zipcode, :price_k, :image_url, :to_param, :score_price, :score_transport]
    }
  end

  def map
    if params[:zoom] && params[:zoom].to_i <= 11
      return @listings = []
    end
    cols = [:id, :title, :display_beds, :baths, :price, :score_price, :score_transport,
            :flag, :lat, :lng, :image_base_url, :image_sizes, :listing_image_id,
            :political_area_id, :zipcode, :formatted_address, :mls_info_id, :is_full_address]
    listings = Listing.enables.where(flag: get_search_flag).select(*cols)
    if params[:ne_lat] && params[:ne_lng] && params[:sw_lat] && params[:sw_lng]
      @listings = listings.where("lat < ? and lat > ?", params[:ne_lat], params[:sw_lat])
                          .where("lng < ? and lng > ?", params[:ne_lng], params[:sw_lng])
      @listings = @listings.where('listings.price >= ?', params[:price_from]) if params[:price_from].present?
      @listings = @listings.where('listings.price <= ?', params[:price_to]) if params[:price_to].present?
      if params[:beds]
        bed_sql = '1'
        bed_arr = params[:beds].split(',').compact
          bed_sql = "listings.beds in (#{bed_arr.join(',')})" if bed_arr.present?
        if params[:beds].include?('4')
          bed_sql = "listings.display_beds in (#{params[:beds].split(',').compact.join(',')}) or listings.display_beds > 4"
        end
        @listings = @listings.where(bed_sql)
      end
      if params[:baths]
        bath_sql = '1'
        bath_arr = params[:baths].split(',').compact
          bath_sql = "listings.baths in (#{bath_arr.join(',')})" if bath_arr.present?
        if params[:baths].include?('2')
          bath_sql = "listings.baths in (#{params[:baths].split(',').compact.join(',')}) or listings.baths > 2"
        end
        @listings = @listings.where(bath_sql)
      end
      @listings = @listings.where('title like ?', "%#{params[:title]}%") if params[:title].present?
      @listings = @listings.order('listings.listing_image_id is null, listings.is_full_address desc, listings.id desc')
    elsif params[:lat].present? && params[:lng].present?
      @listings = listings.where("abs(lat - ?) < 1 and abs(lng - ?) < 1", params[:lat], params[:lng])
        .order("abs(lat - #{params[:lat]}) + abs(lng - #{params[:lng]})").limit(params[:limit] || 200)
    else
      @listings = []
    end
  end

  private
  def get_search_flag
    if params[:flag] && params[:flag] =~ /sale/
      session[:listing_flag] = 0
    else
      session[:listing_flag] = 1
    end
  end
end
