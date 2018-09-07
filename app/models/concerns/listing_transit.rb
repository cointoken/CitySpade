module ListingTransit
  def cancel_cal_transport_distances
    return if self.place_flag < 4
    ActiveRecord::Base.transaction do
      cal_place_flag([4])
      #self.transport_places.destroy_all
      self.transport_distances.destroy_all
      self.score_transport = nil
      self.update_column :score_transport, nil
    end
  end

  def cal_distance_for_mta_line(key = nil)
    if place_flag_hashs[2].include?(self.place_flag) && self.listing_mta_lines.present?
      lines = self.listing_mta_lines.where('distance is not null')
      if lines.present?
        #key ||= Settings.google_maps.server_keys.sample
        #destins = lines.map{|line| "#{line.lat},#{line.lng}"}.join('|')
        #dms = MapsServices::DistanceMatrix.new origins: origins, destinations: destins, units: 'imperial', key: key
        #raise 'google maps api request over limit' unless dms.allow?
        lines.each do |line|
          line.cal_distance
        end
      end
    end
  end

  def stations_near_by(target = nil, r = 1, redo_flag = true)
    sts = MtaInfoSt.where("abs(lat - :lat) < 0.02 and abs(lng - :lng) < 0.02 and sqrt((lat - :lat) * (lat - :lat) + (lng - :lng) * (lng - :lng)) < (0.01 * #{r})", lat: self.lat, lng: self.lng)
      .order("sqrt((lat - #{self.lat}) * (lat - #{self.lat}) + (lng - #{self.lng}) * (lng - #{self.lng}))")#.group(:mta_info_line_id)
    if target
      sts = sts.where(target: target)
    end
    sts = sts
    sts = sts.to_a.uniq{|s| s.mta_info_line_id}
    if sts.blank? && redo_flag
      stations_near_by(target, r * 2, false)
    else
      sts
    end
  end

  def cal_score_price(redo_flag = false)
    return if !redo_flag && self.score_price.present? && !self.changed.any?{|attr| ['beds', 'price', 'political_area_id'].include? attr}
    if self.political_area && self.zipcode && self.price && self.beds
      MapsServices::PriceScore.setup self
    end
  end

  def cal_distance_for_listing_places
    MapsServices::DistanceMatrix.setup self
  end

  def place_flag_hashs
    { 1 => [1, 3, 5, 7],
      2 => [2, 3, 6, 7],
      4 => [4, 5, 6, 7],
    }
  end
  def update_place_flag(n)
    unless place_flag_hashs[n].include?(self.place_flag)
      self.update_column(:place_flag, self.place_flag + n)
    end
  end

  def fix_place_flag
    self.place_flag = 0
    if self.places.present?
      self.place_flag += 1
    end

    if self.listing_mta_lines.present?
      self.place_flag += 2
    end

    if self.transport_distances.size == 12
      self.place_flag += 4
    end
    self.save(validate: false)
  end

  def cal_place_flag(fs)
    if fs.class != Array
      fs= [fs]
    end
    place_flag_i = self.place_flag
    fs.each do |f|
      if place_flag_hashs[f].include? place_flag_i
        place_flag_i -= f
      end
    end
    self.update_column(:place_flag, place_flag_i) if self.place_flag != place_flag_i
  end

  def cancel_listing_places
    return unless self.place_flag > 0
    ActiveRecord::Base.transaction do
      # return if self.listing_places.blank?
      self.listing_places.destroy_all
      self.listing_mta_lines.destroy_all
      cal_place_flag([1, 2])
    end
  end

  def cancel_listing_mta_lines
    return unless  self.place_flag > 2
    ActiveRecord::Base.transaction do
      self.listing_mta_lines.destroy_all
      cal_place_flag([2])
    end
  end

  def cancel_cal
    cancel_listing_places
    cancel_listing_mta_lines
    cancel_cal_transport_distances
  end

  def cancel_old_listing_places
    return unless self.place_flag > 0
    ActiveRecord::Base.transaction do
      self.listing_places.destroy_all
      cal_place_flag([1, 2])
    end
  end

  def cal_score
    # return  if self.place_flag < 4
    MapsServices::CalTransportDistance.setup self
    # if self.city.long_name == 'New York'
    #MapsServices::TransportScore.manhattan query: {id: self.id}
    #MapsServices::TransportScore.brooklyn query: {id: self.id}
    #MapsServices::TransportScore.queens query: {id: self.id}
    #elsif self.city.long_name == 'Philadelphia'
    #MapsServices::TransportScore.philadelphia query: {id: self.id}
    #end
  end

  def retrieve_lines
    MapsServices::RetrieveListingMtaLine.setup self
  end

  def cal_transit(redo_flag = false)
    return unless self.is_enable?
    if redo_flag
      cancel_cal
    end
    is_cal_flag = false
    begin
      if self.place_flag == 0
        unless use_same_listing_transit
          is_cal_flag = true# unless Time.now.month == 9 && Time.now.day == 26
        end
      else
        is_cal_flag = true# unless Time.now.month == 9 && Time.now.day == 26
      end
      if is_cal_flag
        cal_score if self.place_flag < 4
        retrieve_lines unless place_flag_hashs[2].include? self.place_flag
      end
    rescue => e
      Rails.logger.info e
    end
  end
  def use_same_listing_transit
    same_listing = self.same_address_listing
    if same_listing.present? && (same_addresses.size % 7 != 0)# && same_listing.id < 116800 && same_listing.id > 138800
      if same_listing.transport_distances.first
        return false if same_listing.transport_distances.first.created_at < Time.now - 3.month
      else
        return false
      end
      same_listing.listing_mta_lines.each{|s| s.dup.update_attributes listing_id: self.id}
      same_listing.transport_distances.each{|s| s.dup.update_attributes listing_id: self.id}
      self.update_columns place_flag:7, score_transport: same_listing.score_transport
      return true
    end
    false
  end
end
