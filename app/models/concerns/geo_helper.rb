module GeoHelper
  def do_geocode(addr, opt={})
    if opt.blank?
        opt = {key: Settings.google_maps.server_keys.sample}
    end
    begin
      $geocoder.geocode(addr, opt)
    rescue  => err
      if opt.blank?
        sleep 1
        $geocoder.geocode(addr, opt)
      else
        raise err
      end
    end
  end

  def do_reverse_geocode(addr, opt={})
    begin
      $geocoder.reverse_geocode(addr, opt)
    rescue  => err
      if opt.blank?
        sleep 1
        $geocoder.reverse_geocode(addr)
      else
        raise err
      end
    end
  end

  def geo_street_address
    if @geo
      @geo.street_address
    elsif self.respond_to?(:formatted_address) && self.formatted_address
      addrs = self.formatted_address.split(',')
      return addrs[0] if addrs[0] =~ /^\d/ && addrs[1].lstrip !~ /^\d/
      addrs[addrs.size - 4].strip if addrs.size > 3
    end
  end
  def geo_street_name
    if @geo
      @geo.street_name
    elsif geo_street_address
      if geo_street_address =~ /^\d/ && geo_street_address =~ /\d.?\s/
        geo_street_address.sub(/^\S+\s/, '')
      else
        geo_street_address
      end
    end
  end

  def geo_state_name
    if @geo
      @geo.state_name
    elsif self.respond_to?(:formatted_address) && self.formatted_address
      self.formatted_address.split(',')[-2].remove(/\d/).strip
    end
  end

  def geo_zipcode
    if @geo
      @geo.state_name
    elsif self.respond_to?(:formatted_address) && self.formatted_address
      self.formatted_address.split(',')[-2].remove(/\D/).strip
    end
  end

  def geo_address_name
    fl_addr = nil
    if @geo
      fl_addr = @geo.full_address
    elsif self.respond_to?(:formatted_address) && self.formatted_address
      fl_addr = self.formatted_address.split(',')[0]
    end
    if fl_addr && fl_addr.split(',').size > 4
      fl_addr.split(',')[0]
    end
  end

  def geo_like_address
    @geo_like_address ||= if @geo
                            "#{@geo.street_address}, #{@geo.city}"
                            #@geo.full_address.split(',')[0..1].join(',')
                          elsif self.respond_to?(:formatted_address) && self.formatted_address
                            addrs = self.formatted_address.split(',')
                            if addrs.size > 3
                              likes = addrs[-4..-3]
                              if likes[0] && likes[0] =~ /\D\-\D/
                                likes[0] = likes[0].split('-')[0]
                              end
                              likes.join(',')
                            else
                              self.formatted_address
                            end
                          end
  end

  def geo_full_word_address
    if self.formatted_address.present?
      street_suffix_abbrv = [
          ["Ave" ,"Avenue"] ,["St," ,"Street,"],  [" E " ," East "],
          [" W " , " West "] , [" Pl," , " Place,"], ["Pkwy" , "Parkway"],
          ["Blvd" , "Boulevard"], ["Ln" , "Lane"], [" Dr," , " Drive,"],
          ["Ct" , "Court"], [" Dr " , " Drive "] , ["Rd" , "Road"]
        ]
      street =  self.formatted_address
      formatted_addy = street_suffix_abbrv.inject(street) { |street, (k,v)| street.gsub(k,v) }
      if formatted_addy.split(',').size > 4
        formatted_addy.split(', ')[-4..-1].join(', ')
      elsif formatted_addy.split(',').size < 4
        [self.street_address, self.city.short_name, [self.state.short_name, self.zipcode].join(' '), 'USA'].join(', ')
      else
        formatted_addy
      end
    end
  end

  ## listing latlng object for geokit
  def ll
    Geokit::LatLng.new self.lat, self.lng
  end

  def ll_was
    Geokit::LatLng.new self.lat_was, self.lng_was
  end

  def changed_distance
    ll.distance_to ll_was
  end

  def geo(reload_flag = false, addr = nil)
    @geo = (!reload_flag && @geo) || do_geocode(
      addr ||
      (self.lat && self.lng && "#{self.lat},#{self.lng}") ||
      self.formatted_address ||
      "#{self.address_title} #{self.political_area.try :long_name}, #{self.city.try :long_name}")
  end
  def changed_latlng?
    if !new_record? && self.lat.blank? && self.lng.blank? && self.lat_was.present? && self.lng_was.present?
      self.lat, self.lng = self.lat_was, self.lng_was
      false
    else
      (self.changed.include?('lat') || self.changed.include?('lng')) && !new_record? && self.changed_distance > 0.4
    end
  end
end
