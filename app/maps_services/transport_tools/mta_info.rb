module MapsServices
  module TransportTools
    module MTAInfo
      #class << self
        #def setup
          #Subway.setup
          #Bus.setup
          #MapsServices::Septa::Subway.setup
          #MapsServices::Septa::Bus.setup
        #end
      #end
      class Subway
        class << self
          def domain_name
            'http://web.mta.info'
          end
          def base_url      
            'http://web.mta.info/nyct/service/'
          end
          def setup(lclass = ::MtaInfoLine)
            doc = Nokogiri::HTML(RestClient.get(base_url))
            doc.css('.roundCorners table a').each do |a|
              href = a['href']
              next if ['6d', '7d'].any?{|l| a.include? l}
              name = href.split('.').first
              line = lclass.where(name: name, location: 'nyc', mta_info_type: 'subway').first_or_initialize
              icon_url = abs_url(a.css('img').first['src'])
              line.icon_url = icon_url
              line.save
              borough = nil
              Nokogiri::HTML(RestClient.get(abs_url(href))).css('#contentbox table').each do |table|
                ## fix not fount the borough
                title = table.css('tbody>td')
                if title.present?
                  borough = title.text.gsub(/\s/, '')
                end
                table.css('tr').each do |tr|
                  tds = tr.css('td')
                  if tds.size < 3 || tds.size > 5
                    next
                  end
                  if tds.size == 3 
                    if tds[-1].text.strip.present?
                      borough =  tds[-1].text.strip.split(/\/|\s|\-/).first
                    end
                  elsif tds.size == 5
                    if tds[3].text.strip.present?
                      borough = tds[3].text.strip.split(/\/|\s|\-/).first
                    end
                  end
                  next unless tds.first.css('img').first && tds.first.css('img').first['src'].include?("gar")
                  long_name = tds[2].text.strip.gsub(/\n/,'')
                  next if long_name.blank?
                  long_name = long.gsub(/\s+?\(.+\)/, '')
                  name      = long_name.split('/').first
                  if name.match(/^(\d+)/)
                    num_name = name.match(/^(\d+)/)[1]
                  end
                  st = line.mta_info_sts.where(long_name: long_name, target: 'subway_station').first_or_initialize 
                  st.name = name
                  st.num_name = num_name
                  st.borough = borough
                  addrs = st.long_name.split('/').map{|dr| dr.split('-').last.strip}
                  address = addrs.first
                  if addrs.size > 1
                    address << " and #{addrs[1]}"
                  end
                  if st.borough
                    address << ", #{st.borough}"
                  end
                  address << ", NY"
                  address.gsub!('&', 'and')
                  key = Settings.google_maps.server_keys.sample
                  geo = $geocoder.geocode(address, key: key)
                  if geo.success
                    st.lat, st.lng = geo.lat, geo.lng
                  end
                  st.save
                end
              end
            end
          end

          def abs_url(url)
            URI.join(base_url, url).to_s
          end
        end
      end

      class Bus
        class << self
          def base_url
            'http://bustime.mta.info/m/index'
          end
          def setup_buses
            url = 'http://web.mta.info/nyct/service/bus/bussch.htm'
            html = Nokogiri::HTML(RestClient.get url)
            urls = html.css("#contentbox").css("div").last.css('a').map{|m| URI.join(url, m['href']).to_s }
            urls.each do |url|
              doc =  Nokogiri::HTML(RestClient.get url)
              doc.css('.sublev2').each do |bus|
                next if bus.children.size > 1
                MtaInfoLine.where(name: bus.text.strip, mta_info_type: 'bus', location: 'nyc').first_or_create
              end
            end
          end

          def setup
            setup_buses 
            get_url = ->(q) { base_url + "?q=#{q}" } 
            MtaInfoLine.buses.each do |bus|
              url = get_url.call(bus.name)
              doc = Nokogiri::HTML(RestClient.get URI.escape(url))
              next unless doc.css('.route p.routeHeader').present?
              bus.long_name = doc.css('.route p.routeHeader').text.strip
              bus.save
              num = 0
              if !doc.css('.directionForRoute').first || doc.css('.directionForRoute').first.css('.stopsOnRoute li').blank?
                bus.destroy
                next
              end
              doc.css('.directionForRoute .stopsOnRoute li').each do |st|
                if st.css('a').first.blank?
                  next
                end
                s = bus.mta_info_sts.where(name: st.css('a').first.text.strip,target: 'bus_station').first_or_initialize
                s.num_name = num
                address = s.name.gsub('&', 'and') + ', New York, NY'
                key = Settings.google_maps.server_keys.sample
                geo =  $geocoder.geocode(address, key: key)
                if geo.success
                  s.lat, s.lng = geo.lat, geo.lng
                end
                s.save
                num += 1
              end
            end
          end
        end
      end
    end
  end
end
