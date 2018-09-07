module MapsServices
  module TransportTools
    module Chicago
      class Subway
        class << self
          def domain_name
            'http://www.transitchicago.com/'
          end
          def lines_url
            #'http://www.mbta.com/schedules_and_maps/subway/' 
            'http://www.transitchicago.com/travel_information/allrailschedules.aspx'
          end
          def setup
            Nokogiri::HTML(RestClient.get(lines_url)).css('.rrmodinrwrpr .tblsystatus a').each do |line|
              line_name = line.text.strip
              href = URI.join(domain_name, line['href']).to_s
              line = MtaInfoLine.where(name: line_name, location: 'Chicago', mta_info_type: 'subway').first_or_create
              p href
              Nokogiri::HTML(RestClient.get(href)).css('td.title a').each do |st_html|
                st = line.mta_info_sts.new
                st.target = 'subway_station'
                st.long_name = st.name = st_html.text
                href = URI.join(domain_name, st_html['href']).to_s
                res = RestClient.get href
                st_doc = Nokogiri::HTML res
                addr = st_doc.css("#ctl07_divAddress").children.last.text.strip
                geo  = $geocoder.geocode addr
                if geo.success
                  st.lat, st.lng = geo.lat, geo.lng
                end
                #latlng  = CGI::parse(URI(st['href']).query)
                #lat = latlng['lat'].first
                #lng = latlng['lng'].first
                #st_obj = line.mta_info_sts.where(name: st_name).first_or_initialize
                #st_obj.lat, st_obj.lng = lat, lng
                st.save
              end
            end
          end
        end

      end
    end
  end
end
