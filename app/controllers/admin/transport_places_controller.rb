class Admin::TransportPlacesController < Admin::BaseController
  before_filter :require_admin

  def index
    @tplaces = TransportPlace.all
  end

end
