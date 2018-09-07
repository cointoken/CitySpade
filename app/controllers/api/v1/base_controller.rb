class Api::V1::BaseController < Api::BaseController

  helper_method :listing_params
  def listing_params
    @listing_param ||= {
      search: [:northeastlat, :northeastlng, :southeastlat, :southeastlng, 
               :bedroom, :bathroom, :lowprice, :highprice, :rent, :listing_type, :zipcode],
               index: [:id, :title, :price, :baths, :beds, :lat, :lng, :zipcode]
    }
  end
end
