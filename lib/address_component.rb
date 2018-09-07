module AddressComponent
  DEAFULT_TYPES = ['neighborhood', 'postal_code', 'street_address', 'route'] 
  def self.decorator(options={}, url = nil)
    url ||= 'http://maps.googleapis.com/maps/api/geocode/json'
    result_type = options.delete(:result_type) || 'neighborhood'
    begin
      if options.present?
        options.to_options!.merge!(sensor: false, language: :en)
        urls = url.split('?')
        if urls.size == 1
          url = urls.first + '?' + options.to_query
        else
          url ＝ urls.first + '?' + urls[1..-1].join('?') + '&' + options.to_query
        end
        url.gsub!('%2C', ',')
        url.gsub!('%3A', ':')
      end
      result = MultiJson.load(RestClient.get(URI.escape(url)))
    rescue => e
      p e
      return
    end
    if result['results'].present? 
      if  result['results'].size > 1
        first_address = result['results'].delete_at 0
        unless first_address['types'].include? result_type
          unless first_address['types'].any?{|t| DEAFULT_TYPES.include? t }
            return false
          end
        end
        components = []
        result['results'].each do |addr|
          if addr['types'].include? result_type
            addr['address_components'].each do |c|
              if c['types'].include? result_type
                components << c
                break
              end
            end
          end
        end
        if components.present?
          address = []
          first_address['address_components'].each do |addr|
            if addr['types'].include? result_type
              address << components
              address.flatten!
            else
              address << addr
            end
          end
          first_address['address_components'] = address
        end
      else
        first_address = result['results'][0] 
      end 
     # address = []
      #first_address['address_components'].each do |addr|
        #if address.present? && addr['long_name'] == address.last['long_name']
          #if addr['types'].first[0..4] == address.last['types'].first[0..4]
            #address[-1] = addr
          #else
            #address << addr
          #end
        #else
          #address << addr
        #end
      #end
      #first_address['address_components'] = address
      first_address
    end
  end

  def self.get_neighborhood(json)
    json['address_components'].each do |address|
      if address['types'].include? 'political'
        return address['long_name']
      end
    end
    nil
  end
end
