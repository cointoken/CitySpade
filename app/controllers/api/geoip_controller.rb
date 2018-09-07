class Api::GeoipController < Api::BaseController
  def index
    current_geoip
  end

  def outdoor
    if params[:lat].present? && params[:lng].present?
     xml = Nokogiri::XML(RestClient.get("http://cbk0.google.com/cbk?output=xml&ll=#{params[:lat]},#{params[:lng]}"))
      data = xml.xpath('//data_properties').first
      if data
        @data = {lat: data['lat'], lng: data['lng']}
      # @data = params.slice :lat, :lng
      end
    end
    if params[:format] != 'js'
      return render json: @data
    end
    unless @data
      return render nothing: true
    end
  end
end
