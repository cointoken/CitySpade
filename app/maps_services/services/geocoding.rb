module MapsServices
  class Geocoding < Base
    include AddressComponent
    def initialize(options)
      super
      @result_type = @options.delete :result_type
    end
    def base_url
      'https://maps.googleapis.com/maps/api/geocode/json'
    end

    def json
      @json ||= decorator(get)
    end

    def neighborhood_name
      get_neighborhood(json) 
    end

    def address_components
      json['address_components']
    end

    def formatted_address
      json['formatted_address']
    end

    def political_areas
      json['political_areas']
    end

    def lat
      location['lat']
    end

    def lng
      location['lng']
    end

    def zipcode
      address_components.last['long_name'] if address_components.last['types'].include? 'postal_code'
    end

    def location
      json['geometry']['location']
    end
  end
end
