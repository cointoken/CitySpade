class Api::VBase::BaseController < Api::BaseController
  helper_method :listing_params, :current_area
  def listing_params
    @listing_param ||= {
      search: [:northeastlat, :northeastlng, :southeastlat, :southeastlng, 
               :bedroom, :bathroom, :lowprice, :highprice, :rent, :listing_type, :zipcode],
               index: [:id, :title, :price, :baths, :beds, :lat, :lng, :zipcode, :price_k, :flag, :is_full_address]
    }
  end

  def current_area
    @current_area ||= if params[:current_area_id]
                        PoliticalArea.where(id: params[:current_area_id]).first || PoliticalArea.default_area
                      # else
                        # PoliticalArea.default_area
                      end
  end
end
