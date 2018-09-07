module CheckAddress
  def address_is_ok?(addr = nil, full_address = nil, geo = nil)
    addr ||= self.address_title
    full_address ||= self.formatted_address
    return false if geo && self.state_name && geo.state != self.state_name.upcase
    return false if addr.blank? || full_address.blank?
    ## eg. 3049 => 30-49
    return true if addr.split(/\s/).first.sub('-', '') == full_address.split(/\s/).first.sub('-', '')
    # f_addrs = get_address_from_title(full_address).downcase.split(/\s|\-|\,/).reject{|s| s.blank?}[0..1]
    f_addrs = full_address.downcase.split(/\s|\-|\,/).reject{|s| s.blank?}[0..1]
    t_addrs = addr.downcase.split(/\s|\-|\./).reject{|s| s.blank?}[0..1]
    t_first = t_addrs[0].gsub(/\D/, '') if t_addrs[0] =~ /^\d/
    f_first = f_addrs[0].gsub(/\D/, '') if f_addrs[0] =~ /^\d/
    (f_first == t_first) || (t_addrs.any?{|f| f_addrs.include? f})
  end

  def better_address(addr)
    index = addr =~ /(E|N|S|W)\d+.+\D/i
    if index
      addr.insert index + 1, ' '
    else
      addr
    end
  end

  def get_address_from_formatted_address(addr)
    addrs = addr.split(',')
    if addrs.size > 1
      if addrs[0].strip !~ /^\d/ && addrs[1].strip =~ /^\d/
        addrs[1].strip
      else
        addrs[0].strip
      end
    else
      addr
    end
  end
  def get_address_from_title(addr)
    return nil unless addr
    addr = addr.sub(/^0+/, '')
    addr = addr.sub(/(?<=\d)\s+((?=\-\d))/, '')
    addr = addr.split(',').first || ''
    addr = addr.split(/\#|\sunit($|\s)/i).first || ''
    addr = addr.split(/\s(for|\-|\||\:|\(|\–)/).first || ''
    addr = addr.split(/[a-z]+\d+[a-z]+/i).first || ''
    addr = addr.split(/\d\sbeds/).first || ''
    addr = addr.split(/\d\sbaths/).first || ''
    addr = addr.sub(/\s\d\s?(br|ba|bed).?/, '')
    addr = addr.sub(/\s(st|street)\s.+/i, ' st')
    addr = addr.sub(/\sway\s.+/i, ' Way').strip
    # addr = addr.sub(/\d+[a-z]+$/i, '') 
    addr = addr.sub(/[a-z]+\d+[a-z]+/i, '')
    addr = addr.sub(/[a-z]+\d+($|\s)/i, '')
    if addr =~ /\d+\s?[a-z]$/i && addr !~ /(st|street|th|rd|nd)$/i
      addr.sub!(/\d+\s?[a-z]$/i, '')
      addr.strip!
    end
    addr = addr.strip.sub(/\s(\d+)?[a-z]{2,3}$/i, '') if addr && addr !~ /(st|ave|th|nd|rd)$/i
    if addr.present?
      addr = addr.sub(/\.$/, '').sub(/\.\S+?\s/, ' ')
      better_address addr
    else
      nil
    end
  end
  def check_neighbood_is_ok?(area_id = nil, n_name = nil)
    return nil if self.raw_neighborhood.blank? || self.political_area_id.blank?
    area_id ||= self.political_area_id
    n_name ||= self.neighborhood_name
    n_name = n_name.downcase
    target_area = PoliticalArea.find area_id
    return true if target_area.long_name.downcase == n_name || target_area.short_name.downcase == n_name
    target_area.sub_areas.any?{|s| s.long_name.try(:downcase) == n_name || s.short_name.try(:downcase) == n_name} || begin
    origin_areas = self.city.sub_areas.where("long_name = ? or short_name = ?", n_name, n_name)
    origin_areas.any?{|s| s.sub_areas.any?{|s_a| s_a.long_name == target_area.long_name || s_a.short_name == target_area.short_name}}
    end
  end

  def self.included(base) 
    base.extend CheckAddress::ClassMethods
  end

  module ClassMethods
    def regeo_from_error_neighborhood(opts={})
      listings = Listing.enables.where('raw_neighborhood is not null').where(opts)
      listings.each do |l|
        unless check_neighbood_is_ok?
          ct_name = l.city_name
          l.update_columns formatted_address: nil, lat: nil, lng: nil, zipcode: nil, political_area_id: nil
          l.cancel_cal
          l.city_name = ct_name
          l.save
        end
      end
    end
  end
end
