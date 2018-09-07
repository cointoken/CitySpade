class MtaInfoSt < ActiveRecord::Base
  acts_as_mappable
  belongs_to :mta_info_line
  def self.init_latlng(flag = false)
    sts = MtaInfoSt.all
    sts = sts.where("lat is null or lng is null") unless flag
    sts.each do |st|
      if st.geo && st.geo.success?
        st.lat = st.geo.lat
        st.lng = st.geo.lng
        st.save
      end
    end
  end

  def formatted_address(opt={})
    address = "#{long_name || name}"
    if address.include?('station') && address.include?('/')
      address = address.split('/').first
    else
      addrs = address.split('/').map{|dr| dr.split('-').last.strip}
      address = addrs.first
      if addrs.size > 1
        address << " and #{addrs[1]}"
      end
    end
    address.gsub!('&', 'and')
    if borough.present?
      address << ", #{borough}"
    end
    if address.include?('Street, ')
      idx = address.index('Street, ')
      address[idx] = "St, "
    end
    unless opt[:only_station]
      city = opt[:city] || mta_info_line.location
      city = 'New York' if city == 'nyc'
      address << ", #{city}" if city
    end
    case mta_info_line.location
    when 'nyc'
      address << ", NY"
    when 'philadelphia'
      address << ", PA"
    when 'boston'
      address << ", MA"
    end
    address
  end

  def geo(opt={})
    @geo ||= $geocoder.geocode(formatted_address(opt))
    return false unless @geo.success?
    if @geo.place_types.include?('locality') && !opt[:only_station]
      @geo = nil
      return geo(only_station: true)
    end
    return false if @geo.place_types.any?{|s| s =~ /admin/}
    geos = @geo.all.select{|g| g.place_types.any?{|s| s =~ /station$/}}
    if geos.present?
      @geo = geos.first
    end
    @geo
  end

  def reset_latlng
    if geo && geo.success?
      self.lat = geo.lat
      self.lng = geo.lng
      self.save
    end
  end
  def ll
    @ll ||= Geokit::LatLng.new self.lat, self.lng
  end
end
