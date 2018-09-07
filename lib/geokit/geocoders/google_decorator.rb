Geokit::Geocoders::GoogleGeocoder.class_eval  do
  class << self
    # @@spider = Spider::Base.new
    def do_get(url)
      APICount.update :geo
      spider.get(url)
    end

    def spider
      @spider ||= Spider::Base.new
    end

    alias_method :parse_json_without_political_areas, :parse_json
    def parse_json_with_political_areas(results)
      encoded = parse_json_without_political_areas(results)
      first_result = single_json_to_geoloc(results['results'].first)
      all = encoded.all
      encoded = first_result
      encoded.all = all
      encoded.full_political_areas = get_full_political_areas(results)
      encoded.full_political_areas ||= get_full_political_areas(results)
      encoded
    end
    alias_method :parse_json, :parse_json_with_political_areas

    alias_method :set_address_components_without_long_name, :set_address_components
    def set_address_components_with_long_name(loc, addr)
      set_address_components_without_long_name(loc, addr)
      neighborhood = addr['address_components'].select {|comp| comp['types'].include?('neighborhood') }.first
      loc.place_types = addr['types']
      if neighborhood
        loc.long_neighborhood = neighborhood['long_name']
      end
    end
    alias_method :set_address_components, :set_address_components_with_long_name

    def get_full_political_areas(result)
      result_type = 'neighborhood'
      no_politcail = ['administrative_area_level_2', 'administrative_area_level_3', 'administrative_area_level_4']
      if result['results'].present?
        if  result['results'].size > 1
          first_address = result['results'].delete_at 0
          unless first_address['types'].include? result_type
            unless first_address['types'].any?{|t| ['neighborhood', 'postal_code', 'street_address', 'route'].include? t }
              return nil
            end
          end
          components = []
          zip_addr = nil
          sublocality_comp = first_address['address_components'].select{|s| s['types'].include?('sublocality')}[0]# ['long_name']
          sublocality_name = sublocality_comp['long_name'] if sublocality_comp
          result['results'].each do |addr|
            zip_addr = addr['address_components'] if zip_addr.blank? && addr['types'].include?('postal_code')
            if addr['types'].include?(result_type) && addr['types'].include?('political')
              # components << addr['address_components']
              if sublocality_name && addr['types'].any?{|tp| ['neighborhood', 'sublocality'].include? tp}
                next unless addr['formatted_address'].include?(sublocality_name)||addr['address_components'].to_s.include?(sublocality_name)
              end
              components << addr['address_components'].map{|s| s['types'].delete('sublocality_level_1'); s}
            end
          end
          if components.blank?
            if zip_addr
              zip_addr.delete_if{|add| !add['types'].include?('political')}
              components << zip_addr
            end
            result['results'].each do |addr|
              if addr['types'].include?('political')
                components << addr['address_components']
              end
            end
          end

          if components.present?
            first_address['address_components'] = components.flatten#address
          end
        else
          first_address = result['results'].delete_at 0
        end
        first_address['address_components'].delete_if{|comp|
          !comp['types'].include?('political') || comp['types'].any?{|ct| no_politcail.include? ct}
        }
        addrs = first_address['address_components'].reverse.uniq
        delete_flag = false
        addrs.delete_if{|s|
          if s['types'].include?('neighborhood') && !delete_flag
              delete_flag = true
              false
          elsif delete_flag && s['types'].include?('sublocality')
            true
          else
            false
          end
        }
        addrs.reverse.uniq{|s| s['types'].include?('sublocality')? s['types'] : s}.reverse
        # first_address['address_components']#.reverse.uniq
      end
    end

    def submit_url(query_string, options = {})
      language_str = "&language=#{options[:language] || 'en'}"
      query_string = "/maps/api/geocode/json?sensor=false&#{query_string}#{language_str}"
      if options[:key]
        query_string += "&key=#{options[:key]}"
        api_url = "https://maps.googleapis.com" + query_string
      elsif client_id && cryptographic_key
        channel_string = channel ? "&channel=#{channel}" : ''
        urlToSign = query_string + "&client=#{client_id}" + channel_string
        signature = sign_gmap_bus_api_url(urlToSign, cryptographic_key)
        api_url = "https://maps.googleapis.com" + urlToSign + "&signature=#{signature}"
      else
        api_url = "https://maps.googleapis.com" + query_string
      end
      logger.debug api_url
      api_url
    end
  end
end
