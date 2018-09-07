module MapsServices
  module TransportTools
    module Septa
      class Subway
        class << self
          def domain_name
            'http://www.septa.org'
          end
          def lines_map_url
            'http://www.septa.org/maps/system/index.html'
          end
          def setup
            Nokogiri::HTML(RestClient.get('http://www.septa.org/maps/')).css('#septa_main_content .col_content ul.subnav li a').each do |a_doc|
              url = URI.join(domain_name, a_doc['href']).to_s
              next unless url.end_with?("html")
              doc = Nokogiri::HTML(RestClient.get(url))
              doc.css("map#Map area").each do |st|
                href = URI.join(url, st['href']).to_s
                next unless href.include?('subway')
                st_doc = Nokogiri::HTML(RestClient.get href)
                info = st_doc.css("#septa_main_content").first
                content = info.css(".col_content").first
                script = st_doc.css('script')[3].text
                Rails.logger.info url
                Rails.logger.info href
                name = info.css(".full_col .title_img h1").first.text.strip
                name.gsub('-', ' ')
                long_name = content.css('p').first.text.strip
                lat, lng = script.match(/LatLng\((.+)\)/)[1].split(',').map(&:strip)
                lines = content.css('p')[1].children.map{|s| s.text.strip}.delete_if{|s| s.blank? || s =~ /connection/i}
                lines.delete_at 0
                lines.each do |line|
                  obj = MtaInfoLine.where(name: line, location: 'philadelphia', mta_info_type: 'subway').first_or_create
                  st_obj = obj.mta_info_sts.where(name: name, long_name: long_name).first_or_initialize
                  st_obj.target = 'subway_station'
                  st_obj.lat, st_obj.lng = lat, lng
                  st_obj.save
                end
              end
            end
          end
        end
      end
      class Bus
        class << self
          def domain_name
            'http://www.septa.org/'
          end
          def base_url
            'http://www.septa.org/schedules/bus/index.html'
          end
          def setup
            Nokogiri::HTML(RestClient.get(base_url)).css('.full_col .route_bg').each do |route|
              line_name = route.css('.route_num').text.strip
              long_name = route.css('.route_desc').text.strip
              st_url = URI.join(base_url, route.css('.route_days a').first['href']).to_s
              line = MtaInfoLine.where(name: line_name, mta_info_type: 'bus', location: 'philadelphia').first_or_initialize
              line.long_name = long_name
              line.save
              Nokogiri::HTML(RestClient.get(st_url)).css('#timeTable tr:first th').each do |th|
                name = th.children.first.text.strip
                s = line.mta_info_sts.where(name: name, target: 'bus_station').first_or_initialize
                s.long_name = s.name
                s.long_name = s.long_name.gsub(/\s+\(.+\)/, '')
                address = s.name.gsub('&', 'and') + ', Philadelphia, PA'
                key = Settings.google_maps.server_keys.sample
                geo =  $geocoder.geocode(address, key: key)
                if geo.success
                  s.lat, s.lng = geo.lat, geo.lng
                end
                s.save
              end
            end
          end
        end
      end
    end
  end
end
