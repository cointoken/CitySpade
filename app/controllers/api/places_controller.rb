class Api::PlacesController < Api::BaseController
  def autocomplete
    json = Google::Place.autocomplete(params[:query] || params[:q], autocomplete_opts)
    render json: {suggestions: json[:places].map{|pl| pls = pl[:name].split(',')
                                                 name = pls.size > 3 ? pls[0...-3].join(',') : pl[:name]
                                                 parent = pls.size > 3 ?  "#{pls[-3]}, #{pls[-2]}" : ''
                                         {name: name, parent: parent,value: name, data: Time.now.to_i}}}
  end
  def cities
    @cities = City.select(:name, :state,:id, :long_state)
    if params[:state]
      @cities = @cities.where(state: params[:state])
    end
    if params[:query]
      @cities = @cities.where('name like ?', "#{params[:query]}%")
    end
    @cities = @cities.order('hot desc').limit 20
    render json: {suggestions:@cities.map{|city| {name: "#{city.name}, #{city.state}",
                                                  parent: city.state, data: city.id, value: "#{city.name}, #{city.state}", id:city.id}}}
  end

  def any_neighborhoods
    return render json: nil if params[:query].blank? || params[:query].size < 3
    @neighborhoods = PoliticalArea.where('long_name like ?', "#{params[:query]}%").order(depth: :desc)
    @neighborhoods = @neighborhoods.to_a.uniq{|s| s.full_name}
    render json: {suggestions: @neighborhoods.map{|neigh|
      {
        name: neigh.full_name, data: neigh.id, value: neigh.full_name,id: neigh.id,
        ne_lat: neigh.ne_lat, ne_lng: neigh.ne_lng, sw_lat: neigh.sw_lat, sw_lng: neigh.sw_lng,
        lat: neigh.lat, lng: neigh.lng
      }
    }}
  end

  def set_city
    @current_city = City.find params[:id]
    session[:current_city_id] = @current_city.id
    render json: nil
  end

  def states
    render json: City.states
  end

  def coordinates
    @area = PoliticalArea.find params[:area_id]
    render json: {coordinates: @area.coordinates}
  end

  private
  def autocomplete_opts
    opts={language: :en}
    opts[:location] = "#{(current_city || current_geoip).lat},#{(current_city || current_geoip).lng}"
    opts[:radius] = 60000
    opts
  end
end
