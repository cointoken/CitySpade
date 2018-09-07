module Geokit
  module Geocoders
    class IPApiGeocoder < Geocoder
      private
      def self.do_geocode(ip)
        process :json, submit_url(ip)
      end

      def self.submit_url(ip)
        "http://ip-api.com/json/#{ip}"
      end

      JSON_MAPPINGS = {
        :city         => 'city',
        :state        => 'regionName',
        :zip          => 'zip',
        :country_code => 'countryCode',
        :lat          => 'lat',
        :lng          => 'lon'
      }

      def self.parse_json(json)
        loc = new_loc
        JSON_MAPPINGS.each do |key, value|
          loc.send("#{key}=", json[value])
        end
        loc.success = !!loc.city && !loc.city.empty?
        loc
      end 
    end
  end
end
