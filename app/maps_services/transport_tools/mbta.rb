module MapsServices
  module TransportTools
    module Mbta 
      def self.setup
        Subway.setup
        Bus.setup
      end
      class Subway
        class << self
          def domain_name
            'http://www.mbta.com/'
          end
          def lines_url
            'http://www.mbta.com/schedules_and_maps/subway/' 
          end
          def setup
            Nokogiri::HTML(RestClient.get(lines_url)).css('.routes a').each do |line|
              line_name = line.text.strip
              href = URI.join(domain_name, line['href']).to_s
              line = MtaInfoLine.where(name: line_name, location: 'boston', mta_info_type: 'subway').first_or_create
              p href
              Nokogiri::HTML(RestClient.get(href)).css('#timetable table a').each do |st|
                st_name = st['title']
                latlng  = CGI::parse(URI(st['href']).query)
                lat = latlng['lat'].first
                lng = latlng['lng'].first
                st_obj = line.mta_info_sts.where(name: st_name).first_or_initialize
                st_obj.target = 'subway_station'
                st_obj.lat, st_obj.lng = lat, lng
                st_obj.save
              end
            end
          end
        end
      end

      class Bus
        class << self
          def domain_name
            'http://www.mbta.com/'
          end
          def lines_url
            'http://www.mbta.com/schedules_and_maps/bus/'
          end
          def setup
            Nokogiri::HTML(RestClient.get(lines_url)).css('#bus_list li a').each do |line|
              line_name = line.text.strip
              href = URI.join(domain_name, line['href']).to_s
              line = MtaInfoLine.where(name: line_name.split('-').first.strip, location: 'boston', mta_info_type: 'bus').first_or_initialize
              line.long_name = line_name.split('-').last.strip
              line.save
              doc = Nokogiri::HTML(RestClient.get(href)).css('#timetable table.timetable tr').first 
              next if doc.blank?
              doc.css("th").each do |st|
                st_name = st.text.strip
                st_obj = line.mta_info_sts.where(name: st_name).first_or_initialize
                st_obj.target = 'bus_station'
                st_obj.reset_latlng
                st_obj.save
              end
            end
          end
        end
      end
    end
  end
end

