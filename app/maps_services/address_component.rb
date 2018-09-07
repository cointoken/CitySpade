module MapsServices
  module AddressComponent
    DEAFULT_TYPES = ['neighborhood', 'postal_code', 'street_address', 'route', 'establishment'] 
    EXCEPT_TYPES  = ['administrative_area_level_2', 'administrative_area_level_3']
    def decorator(json = {}, result_type = 'neighborhood')
      result_type ||= 'neighborhood'
      result = JSON.parse(json)
      if result['results'].present? 
        first_address = result['results'].delete_at 0
        if  result['results'].size >  0
          first_address['political_areas'] = []
          unless first_address['types'].include? result_type
            unless first_address['types'].any?{|t| DEAFULT_TYPES.include? t }
              return false
            end
          end

          result['results'].each do |addr|
            if addr['types'].any?{ |t|  result_types(result_type).include?(t) }
              first_address['political_areas'] << addr['address_components']
            end
          end
        else
          first_address['political_areas'] = first_address['address_components'].clone
        end
        
        first_address['political_areas'].flatten!
        first_address['political_areas'].delete_if{|addr| !addr['types'].include?('political') || addr['types'].any?{
          |t| EXCEPT_TYPES.include?(t)} }
        first_address['political_areas'].delete_if{ 
          |addr| 
          !political_types.include?(addr['types'].first) || addr['long_name'] =~ /\d/ }
        first_address['political_areas'].uniq!{ |addr| addr['types'].first + addr['short_name']}
        sort_by_political first_address
      end
    end

    def sort_by_political(addrs)
      addrs['political_areas'].reverse!.sort!{|x,y| political_types.index(x['types'].first) <=> political_types.index(y['types'].first)}
      addrs['political_areas'].uniq!{ |area|
        if area['types'].include? 'locality'
          'locality'
        else
          area['types'].first + area['short_name']
        end
      }
      addrs
    end

    def result_types(t) 
      if t == 'neighborhood'
        ['neighborhood', 'locality', 'sublocality']
      else
        [t]
      end
    end

    def political_types
      [
        'country',
        'administrative_area_level_1', 
        'administrative_area_level_2', 
        'administrative_area_level_3',
        'locality', 'sublocality', 'neighborhood']
    end

    def get_neighborhood(json)
      json['address_components'].each do |address|
        if address['types'].include? 'neighborhood'
          return address['long_name']
        end
      end
      nil
    end
  end
end
