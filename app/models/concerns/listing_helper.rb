module ListingHelper
  include GeoHelper
  include ListingTransit
  include ListingSpider
  def same_addresses opt={}
    listings = Listing.all
    if !opt[:include_self]
      listings = listings.where('id != ?', self.id)
    end
    listings = listings.within(opt[:within] || 0.005, units: :kms, origin: [self.lat, self.lng])
    listings = listings.where(political_area_id: self.political_area_id, formatted_address: self.formatted_address)
    listings
  end

  def same_address_listing
    same_addresses.accessibles.where('id != ?', self.id).where(place_flag: 7)
      .order(id: :desc).first || Listing.within(0.005, units: :kms, origin: [self.lat, self.lng])
      .where(place_flag: 7).where('id != ? and created_at > ?', self.id, Time.now - 3.month).order(id: :desc).first
  end

  #def street_address
  #read_attribute(:street_address) || read_attribute(:title)
  #end
  def state
    self.political_area.try(:state)
  end

  def images
    if self.account_id
      photos
    else
      listing_images
    end
  end

  def city
    self.political_area.try(:city) #|| PoliticalArea.where(target: 'locality', long_name: @city_name).first
  end

  def state_name
    @state_name || state.try(:short_name)
  end
  def city_name
    @city_name || city.try(:long_name)
  end

  def img_alt(i = nil)
    img_alt_str = "#{self.title}, #{self.political_area.try :long_name}, #{self.city.try :long_name}, #{self.state.try :short_name}"
    if i
      img_alt_str += ", #{i}"
    end
    img_alt_str
  end

  def is_rental?
    self.flag == Settings.flags.rental
  end

  def is_sale?
    !is_rental?
  end

  def can_access?
    self.status < 20 #&& self.political_area
  end

  def is_expired?
    self.status == 1
  end

  def is_enable?(flg=false)
    flg ? self.status == 0 : !is_expired?
  end

  # 在account的listings中有些是过了日期被deactve的，状态为-1
  def is_deactived?
    self.status == -1
  end

  ## can accessible?
  def is_accessible?
    self.status < 20
  end

  def has_review?
    review_building && review_building.reviews_count > 0
  end

  def price_k
    if self.price
      tmp = self.price / 1000.0
      if self.is_rental?
        "$#{tmp.round(2)}K"
      else
        "$#{tmp.to_i}K"
      end
    end
  end

  def set_expired(opt = {})
    st_i = opt[:status] || 1
    if opt[:target]
      case opt[:target].to_sym
      when :url
        st_i = 30
      when :address
        st_i = 20
      end
    end
    self.update_columns(status: st_i, updated_at: Time.now)
  end

  def reset_latlng(latlng_flag = true)
    self.political_area = nil
    self.zipcode = nil
    self.score_price = nil
    unless latlng_flag
      self.lat, self.lng = nil, nil
    end
    self.formatted_address = nil
    self.save
  end

  def url=(href)
    @url = self.origin_url = href
  end

  def final_url
    ## for Ideal properties Group
    return nil if self.broker_id == 6000
    url || (!new_record? && url_from_broker)
  end

  def improve_address_from_latlng_or_title
    #if self.flag == 1 && self.price && self.price > 200000
    ### elliman spider post error, sale become rent
    #Rails.logger.info  self
    #return false
    #end
    # fix same neighborhood in difference city
    #if neighborhood_name.present? && neighborhood = PoliticalArea.find_neighborhood(neighborhood_name, city)
    #self.political_area = neighborhood
    ## self.political_area_lft = self.political_area.lft
    #end
    if self.changed_latlng?
      self.city_name    = self.city.try(:long_name) unless @city_name
      self.formatted_address = nil
      self.zipcode = nil
      self.political_area = nil
    end
    if self.changed.include?('title')
      self.street_address = nil if !self.is_mls? && !self.changed.include?('street_address')
      unless self.changed.any?{ |key| ['lat','lng'].include? key }
        self.lat, self.lng = nil, nil
        if self.political_area
          # self.neighborhood_name = self.political_area.long_name
          self.city_name         = self.city.try(:long_name) unless @city_name
          self.formatted_address = nil
          # self.zipcode = nil
          self.political_area = nil
        end
      end
    end
    if self.lat.blank? || self.lng.blank? || self.political_area_id.blank? #|| self.changed.any?{ |key| ['lat','lng'].include? key }
      reimprove_address
    end
  end
  def save_url
    # return if self.is_cal
    if self.url.present?
      self.urls.where(url: url).first || self.urls.create(url: url)
    end
  end

  def check_and_regeo(tmp_name = nil)
    unless address_is_ok?
      tmp_name ||= self.city_name || 'new york'
      self.cancel_cal
      self.update_columns formatted_address: nil, lat: nil, lng: nil, political_area_id: nil, zipcode: nil, score_transport: nil, score_price: nil
      self.city_name = tmp_name
      self.save
    end
  end

  def shadowy_long_address(reget_flag = false, opt={})
    if self.formatted_address.present? && !reget_flag
      self.formatted_address
    else
      addr = self.address_title || ""
      addr = addr.split(',').first if addr.present?
      if self.neighborhood_name.present? && !opt[:exclude_neigh]
        addr << ", #{self.neighborhood_name}"
      end
      addr << ", #{self.city_name}" if self.city_name.present?
      addr << ", #{self.state_name}" if self.state_name.present?
      addr << ", #{self.zipcode}" if self.zipcode.present? && !opt[:exclude_neigh]
      addr << ', USA'
      addr.sub(/^\,/, '')
      addr
    end
  end

  def display_title
    if changed? && changed.include?('title')
      read_attribute(:title)
    else
      tl = is_full_address ? geo_street_address : geo_street_name
      org_title = read_attribute(:title) || ''
      if !tl || (tl =~ /^\d+\-\d/ && org_title =~ /^\d+\s/\
          && tl.split(' ').first.remove(/\D/).size > org_title.split(' ').first.remove(/\D/).size)\
        || (tl =~ /^\d+\-\d+\-\d/ && org_title =~ /^\d/)
        #if !tl || (tl =~ /^\d+\-\d+\-\d/ && org_title =~ /^\d/)
        tl = org_title.split(/\sunit/i).first.titleize
      end
      if self.unit.present? && self.unit !~ /\$/
        tl = (tl.split('#', 2).first || '').strip
        tl << " ##{self.unit.remove(/^\#/).strip.upcase}"
      else
        tl
        #elsif read_attribute(:title)
        #read_attribute(:title).start_with?(tl) ? read_attribute(:title) : tl
      end
    end
  end

  def reimprove_address(redo_flag = false, key = nil,regot = nil)
     key ||= Settings.google_maps.server_keys.sample
    return self if self.status >= 20
    ##
    # return if !self.new_record? || redo_flag
    geo = nil
    if (self.lat.blank? || self.lng.blank?) || (self.is_full_address && (self.neighborhood_name.present? || self.zipcode.present?))
      geo = do_geocode(self.shadowy_long_address(true, exclude_neigh: regot), key: key)
      if geo.success
        if self.address_title
          if !address_is_ok?(self.address_title, geo.street_address || geo.full_address, geo) || (geo.full_address !~ /\d{5}/ && geo.full_address.split(',').size < 4)
            ## get google api again exclude neighborhood
            return reimprove_address(redo_flag, key, true) unless regot
            self.status = 20
            return self
          end
        end
        self.formatted_address = geo.full_address # if self.formatted_address.blank?
        self.street_address  = geo.street_address
        self.lat = geo.lat
        self.lng = geo.lng
      else
        return self
      end
    end
    if self.political_area.blank? || redo_flag || self.zipcode.blank?
      latlng = Geokit::LatLng.new(self.lat, self.lng)
      geo = do_reverse_geocode(latlng, key: key)
      if geo.success
        self.political_area = PoliticalArea.retrieve_from_address_compontents(geo.full_political_areas) || self.political_area
        # self.political_area_lft = self.political_area.try :lft
        self.zipcode = geo.zip if self.zipcode.blank? && geo.zip
        # self.formatted_address ||= geo.full_address
        self.formatted_address ||= geo.full_address # if self.formatted_address.blank?
        self.street_address    ||= geo.street_address
      end
    end
    if geo
      if self.is_full_address
        self.title = geo.street_address if geo.street_address && self.title.blank?
      else
        self.title = geo.street_name if geo.street_name && self.title.blank?
      end
    end
    if changed.include? 'formatted_address'
      set_building_venue
      BuildingListing.binding_building self if self.no_fee || self.is_full_address
    end
    self
  end

  def titleize_for_title
    if self.title.blank? && self.formatted_address
      self.title = (self.is_full_address && self.geo.street_address) || self.geo.street_name || self.geo.neighborhood
      # self.title = self.formatted_address.split(',').first
      # self.title.gsub!(/^\d+((\-|\s)+\d+)?\s/,'') unless self.is_full_address
    end
    if self.title.present?
      self.title = self.title.split(',').first.split(' ').map(&:camelize).join(' ')
    end
    if self.lat && self.lng
      if self.lat < 0 && self.lng > 0
        self.lat, self.lng = self.lng, self.lat
      end
    end
    true
  end

  def beds
    read_attribute(:display_beds)
  end

  def read_beds
    read_attribute(:beds) || 0
  end

  def address_title
    @address_title ||= begin
                         if read_attribute(:street_address).present?
                           better_address read_attribute(:street_address).sub(/^0+|\.$/, '').sub(/\.\S+?\s/, ' ')
                         else
                           get_address_from_title(read_attribute(:title)) || title
                         end
                       end
  end

  def flag_name
    is_rental? ? Settings.listing_flags.rental : Settings.listing_flags.sale
  end
  def description
    @description || if self.listing_detail.try(:description).present?
    self.listing_detail.description
    else
      if self.building && self.building.description
        self.building.description
      else
        'Not Specified'
      end
    end
  end
  def amenities
    @amenities || begin
    if self.listing_detail.try(:amenities).present?
      tmp = self.listing_detail.amenities
      if !tmp.is_a?(Array)
        [tmp]
      else
        tmp
      end
    elsif self.building
      self.building.amenities.present? ? self.building.amenities : ['Not Specified']
    else
      ['Not Specified']
    end
    end
  end

  def check_listing
    if changed_latlng? || changed.include?('political_area_id')
      self.cancel_cal
    end
    self.display_beds = self.read_beds.ceil
    if self.broker_id.blank? && self.broker_name.present?
      bk = Broker.find_broker_by_name(self.read_attribute(:broker_name).strip, self.state_name).first_or_create
      self.broker_id = bk.id
    end
    if self.no_fee.blank?
      if self.amenities.any?{|s| s =~ /no(\-|\s+)(broker\s+)?fee/i } || ((self.description || '') =~ /no(\-|\s+)(broker\s+)?fee/i)
        self.no_fee = true
      else
        self.no_fee = false
      end
    end
    ## set nestio no fee listing to full address listing at all time
    if self.no_fee && self.url.blank? && self.title =~ /^\d+(\-\d+)?\s/
      self.is_full_address = true
    end

    if self.is_full_address && self.display_title =~ /^\D/
      self.is_full_address = false
    elsif self.is_full_address.nil?
      if self.title =~ /^\d+(\-\d+)?\s/
        self.is_full_address = true
      else
        self.is_full_address = false
      end
    end
    disable_from_neighborhood if changed.include?('political_area_id') || changed.include?('status')
    true
  end

  def check_listing_after_create
    if self.is_rental?
      ## for price errors, Brookly
      if self.beds == 0 && self.price > 3800 && self.political_area.present?
        if PoliticalArea.where('lft < ? and rgt > ?', self.political_area.lft, self.political_area.rgt).exists?(long_name: 'Brooklyn')
          if PoliticalArea.where('lft <= ? and rgt >= ?', self.political_area.lft, self.political_area.rgt).exists?(long_name: ['DUMBO', 'williamsburg'])
            self.update_columns status: 34 if self.price > 5000
          else
            self.update_columns status: 34
          end
        end
      end
    end
  end

  def disable_from_neighborhood doflag = false
    return unless [0, 3].include? self.status
    ## PCVST, Peter Cooper Village, Stuyvesant Town
    if PoliticalArea.pcvst_ids.include?(self.political_area_id) && self.broker_name != 'StuyTown Apartments'
      self.status = 3
    else
      self.status = 0 if self.status == 3
    end
    self.update_columns status: self.status if doflag
  end

  def set_building_venue doflag = false
    if self.is_full_address && self.formatted_address.present? && self.title =~ /\d+\s/ && self.geo_like_address.present? && self.is_enable?
      #v = Venue.buildings.where(formatted_address: self.formatted_address).first
      v = Venue.buildings.where('formatted_address = ? or formatted_address like ? or formatted_address like ?',
                                self.formatted_address, self.geo_like_address, self.geo_full_word_address).first
      if v && v.reviews.size > 0
        if doflag
          self.update_columns building_venue_id: v.id
        else
          self.building_venue_id = v.id
        end
        if self.geo_like_address.size > 15
          retries = 0
          begin
            Listing.where(building_venue_id: nil, is_full_address: true).where('formatted_address = ? or formatted_address like ? or formatted_address like ?',
                                                                               self.formatted_address, self.geo_like_address, self.geo_full_word_address?)
            .update_all building_venue_id: v.id
          rescue  ActiveRecord::StatementInvalid => ex
            if ex.message =~ /Deadlock found when trying to get lock/ #ex not e!!
                retries += 1
                raise ex if retries > 3  ## max 3 retries
                sleep 10
                retry
            else
                raise ex
            end
          end
        else
          Listing.where(building_venue_id: nil, is_full_address: true).where('formatted_address = ?',
                                                                             self.formatted_address)
            .where.not(id: self.id).update_all building_venue_id: v.id
        end
      end
    end
  end

  def save_detail
    return if self.is_expired?
    # return if self.is_cal
    unless self.listing_detail
      self.build_listing_detail
    end
    if @open_houses.present?
      @open_houses.each{|oh| self.open_houses.where(oh.slice(:open_date)).first_or_initialize.update(oh)}
    end
    return if @description.blank? && @amenities.blank?
    if self.listing_detail.description != self.description || self.listing_detail.amenities != self.amenities
      self.listing_detail.description = @description    # if self.description &&
      self.listing_detail.amenities = @amenities        #if self.amenities && self.amenities.first != 'Not Specified'
      @detail_hash.present? ? self.listing_detail.update_attributes(@detail_hash) : self.listing_detail.save
    elsif @detail_hash.present?
      self.listing_detail.update_attributes @detail_hash
    end

  end
  # get broker site listing web id
  def origin_listing_id
    case self.broker_site_name
    when 'citi-habitats'
      reg = self.origin_url.match(/\/(\d+)\//)
      if reg
        reg[1]
      end
    else
      nil
    end
  end

  def sync_expired_status(doc = nil)
    if self.url && self.broker_site_name
      site_name = self.broker_site_name.gsub('-', '_')
      if Spider::Improve::DeleteListing::PROC_DELETE.keys.include?(site_name)
        unless doc
          res = RestClient.get self.url
          doc = Nokogiri::HTML res.try(:to_utf8) || res
        end
        hash = {status: 0}
        hash.merge!(Spider::Improve::DeleteListing::PROC_DELETE[site_name].call(doc)||{})
        self.update_columns hash.merge updated_at: Time.now
      end
    end
  rescue => err
    unless err.try(:http_code)
      self.update_columns status: 31, updated_at: Time.now
    else
      self.update_columns status: 1, updated_at: Time.now if err.http_code.to_s =~ /^4/
    end
  end


  def self.included(base)
    place_flag_hashs = {
      1 => [1, 3, 5, 7],
      2 => [2, 3, 6, 7],
      4 => [4, 5, 6, 7],
    }

    base.scope :rentals, -> { base.where(flag: 1) }
    base.scope :sales, -> { base.where(flag: 0) }
    base.scope :latlngs, -> { base.where('political_area_id is not null and lat is not null and lng is not null and listings.zipcode is not null') }
    base.scope :enables, -> { base.where(status: 0).where("title is not null and formatted_address is not null").latlngs }
    base.scope :accessibles, -> { base.where('title is not null and status < ?', 20) }
    base.scope :expired, -> { base.where('listings.status > 0').latlngs }
    base.scope :deactived, -> { base.where('listings.status = -1').latlngs }
    base.scope :open_houses, -> { base.where(id: OpenHouse.select(:listing_id).distinct(:listing_id)) }
    base.scope :all_listings_of_area, ->(area) { base.where(political_area_id: area.sub_ids(include_self: true)) }
    base.scope :no_latlngs, -> { base.unscoped.where('lat is null or lng is null or political_area_id is null or listings.zipcode is null') }
    base.scope :no_places, -> { base.unscoped.enables.where("place_flag not in (#{place_flag_hashs[1].join(',')})") }
    base.scope :no_mta_lines, -> { base.unscoped.enables.where("place_flag not in (#{place_flag_hashs[2].join(',')}) and place_flag in  (#{place_flag_hashs[1].join(',')})") }
    base.scope :no_cal_transport_distances, -> { base.unscoped.enables.where("place_flag not in (#{place_flag_hashs[4].join(',')})") }
    base.scope :cal_transport_distance, -> { base.unscoped.enables.where("place_flag in (#{place_flag_hashs[4].join(',')})") }
    base.scope :default_order, -> {
      base.order('listings.listing_image_id is null, listings.is_full_address desc')
        .order('score_price + score_transport desc')
    }
    base.scope :default_order_by_loc, ->(lat, lng, num = 3, diff = 3){
      base.order("FORMAT((abs(listings.lat - #{lat}) + abs(listings.lng - #{lng})) / #{diff}, #{num})").default_order
    }
    base.before_save :titleize_for_title
    base.before_save :improve_address_from_latlng_or_title
    base.before_save :cal_score_price
    base.before_save :check_listing
    base.after_save :save_url
    base.after_save :check_listing_after_create, if: ->(l) { l.can_access? }
    base.after_save :save_detail, if: ->(l){ l.can_access? }
    base.after_save :cal_transit, if: ->(l){ l.can_access? && l.account_id.blank? }
    base.extend ListingHelper::ClassMethods
  end

  module ClassMethods

    #delegate :default_sizes, to: :ListingImage
    def clear_expired_images(opt = {})
      return unless respond_to?(:expired)
      expired.where('updated_at < ?', Time.now - 7.day).where(opt).each do |obj|
        obj.images.offset(1).destroy_all
      end
    end

    def destroy_expired_before_of tm = 1.month
      Listing.expired.where('updated_at < ?', Time.now - tm).destroy_all
    end

    def improve_addresses(query = 'lat is null or lng is null or political_area_id is null or place_flag is null or zipcode is null or formatted_address is null')
      unscoped.enables.where(query).order('id desc').each do |listing|
        listing.reimprove_address(true).save
        if listing.lat.blank? || listing.lng.blank? || listing.political_area.blank?
          break
        end
        if listing.lat && listing.lng && listing.lat < 0 && listing.lng > 0
          lat = listing.lat
          listing.lat = listing.lng
          listing.lng = lat
          listing.reimprove_address(true).save
        end
        if listing.political_area && listing.zipcode.blank?
          listing.lat = nil
          listing.lng = nil
          listing.save
          listing.reimprove_address(true).save
        end
      end
      Listing.no_latlngs.where('updated_at < ?', Time.now - 5.day).destroy_all
    end

    def get_listing_from_spider(listing_hash, default_city = nil, check_attrs = {})
      hash = listing_hash.dup
      opt = {}
      is_citi_habitats = false
      if hash[:url]
        listing = find_duplicate_by_url(hash)
        if listing && listing != []
          return listing
        end
        is_citi_habitats = true if hash[:url].include?('citi-habitats.com')
      end
      attr_arrs = [:beds, :unit, :baths, :formatted_address,:flag, :lat, :lng, :contact_name]
      if hash[:street_address]
        attr_arrs << :street_address
      else
        attr_arrs << :title
      end
      attr_arrs.each do |key|
        opt[key] = hash[key] if hash[key].present?
      end
      if (opt[:title] || opt[:street_address]).blank?
        return nil
      end
      diff_price = (opt[:flag] == 0 ? 10000 : 100)
      listings = where(opt)
        .where('listings.updated_at > ?', Time.now - 30.day)
        .where("abs(listings.price - #{hash[:price]}) < #{diff_price}")
        .order('listings.updated_at desc')
      if !hash[:never_has_url]
        listings = listings.where('origin_url like ?', "http://#{URI(hash[:url]).host}%") if opt[:lat].blank?
        if is_citi_habitats
          listings = listings.where('origin_url like ?', 'http://www.citi-habitats%')
        else
          listings = listings.where('origin_url not like ?', 'http://www.citi-habitats%')
        end
      else
        listings = listings.where(origin_url: nil)
      end
      if listings.present?

        if !hash[:never_has_url]
          listings.each do |listing|
            if listing.urls.where(url: hash[:url]).first
              return listing
            end
          end
        end
        listing = listings.where(price: hash[:price]).first
        return listing if listing && listing.city.try(:long_name).try(:downcase) == (default_city || hash[:city_name].try(:downcase))
        listings.each do |listing|
          if listing.political_area && listing.political_area.city
            if listing.political_area.city.long_name == (default_city || listing_hash[:city_name])
              if check_attrs.present?
                return listing if !check_attrs.any?{|k, v| listing.send(k) != v}
              else
                return listing
              end
            end
          end
        end
      end
      nil
    end

    def find_duplicate_by_url(hash)
      if hash[:contact_name] == "Bozzuto Management" || hash[:contact_name] == "Equity Residential" || hash[:contact_name] == "AvalonBay Communities"
        listing = Listing.where(title: hash[:title], unit: hash[:unit], status: 0).order('updated_at DESC').first
        return listing if listing
      else
        listing = Listing.find_by_origin_url(hash[:url])
        return listing if listing
        urls = ListingUrl.where(url: hash[:url])
        urls.each do |url|
          if url.listing && url.listing.flag == hash[:flag]
            return url.listing
          else
            return nil
          end
        end
      end
    end

    def cal_score_prices(redo_flag = false)
      query = '1'
      unless redo_flag
        query = '(score_price is null or score_price = 0) and price > 0'
      end
      Listing.rentals.where(query).each do |listing|
        listing.save
      end
    end


    def recal_score_price_for_except_nyc(opt = {})
      Listing.enables.rentals.where(political_area: PoliticalArea.nyc.nearby_areas).each do |l|
        MapsServices::PriceScore.setup l
        l.update_column :score_price, l.score_price
      end
      PoliticalArea.philadelphia.all_listings.enables.rentals.where(opt).each do |l|
        MapsServices::PriceScore.setup l
        l.update_column :score_price, l.score_price
      end
      PoliticalArea.boston.all_listings.enables.rentals.where(opt).each do |l|
        MapsServices::PriceScore.setup l
        l.update_column :score_price, l.score_price
      end
    end

    def fix_listings_place_flag
      place_flags = new.place_flag_hashs.values.flatten.uniq
      where("place_flag not in (#{place_flags.join(',')})").each do |listing|
        listing.fix_place_flag
      end
    end

    ALL_SITES = begin
                  sites = Spider::Sites::Base.descendants.map{|s|s.to_s.split("::").last.downcase}
                  sites.delete 'base'
                  sites.delete 'citihabitats'
                  sites << 'citi-habitats'
                  sites << Spider::Feeds::Base.descendants.map{|s| s.to_s.split('::').last.downcase}
                  sites.flatten!
                  sites.sort
                end

    FEED_SITES = begin
                   Spider::Feeds::Base.descendants.map{|s| s.to_s.split('::').last.downcase}
                 end

    def all_sites
      ALL_SITES
    end

    def rentlinx_sites
      self.rentlinx.map{|s| s.broker.name}.uniq
    end

    def nestio_sites
      sites = Spider::Feeds::Base.descendants.select{|s| s.try(:extend_trulia?)}
      sites = sites.map{|s| s.to_s.split("::").last.downcase}
      sites.sort
    end

    ALL_SITES.each do |site|
      ## tfc isn't mls broker
      class_eval <<-SITE_METHOD, __FILE__, __LINE__ + 1
        def #{site.gsub('-', '')}
          if ListingProvider.has_client?("#{site}")
            return Listing.where(id: ListingProvider.where(client_name: "#{site}").pluck(:listing_id))
          end
          if FEED_SITES.include?("#{site}") && ['realtymx', 'messagekast'].include?("#{site}")
            listings_by_mls "#{site}"
          else
            where('origin_url like ?', "%#{site}.com%")
          end
        end
      SITE_METHOD
    end

    def general_sites
      feeds_sites ||= Dir[Rails.root.join('app/spider/feeds', '*.rb')].map{|s|File.split(s).last.remove(/\_|\.rb/).downcase}
      no_feed_sites ||= Dir[Rails.root.join('app/spider/sites/*/', 'no_fee_*.rb')].map{|s| File.split(s).last.remove(/^no\_fee\_|\.rb/).downcase}
      sites = ALL_SITES - feeds_sites - no_feed_sites
      options = ["related", "tfc", "hlresidential", "all"]
      sites << options
      sites.flatten!.sort
    end

    def listings_by_mls mls
      Listing.where("listings.id in (select listing_id from mls_infos where name = ?)", mls)
    end

    def delete_references_of_expired(expired_at = Time.now - 1.month)
      listings = Listing.expired.where('updated_at < ?', expired_at)
      listings.each do |listing|
        DeleteListingReferenceWorker.perform_async(listing.id)
      end
    end

    def fix_is_full_address_or_title
      Listing.enables.where(is_full_address: true).where('title regexp ?', '^([1-9]+)[a-z]+').where.not(origin_url: nil).each do |l|
        l.update_column :is_full_address, false
      end
      reg = '(:)|([0-9] ?(bed|bd)[a-z]+)|([0-9] ?bath[a-z]+)'
      Listing.enables.where('title regexp ?', reg).each do |l|
        title = l.title.split(/#{reg}/i).map &:strip
        if title.first.size > 15
          l.title = title.first
        elsif title.last.size > 15
          l.title = title.last
        else
          l.title = l.political_area.short_name
        end
        if l.title =~ /\d+\s/
          l.update_columns is_full_address: true, title: l.title
        else
          l.update_columns is_full_address: false, title: l.title
        end
      end
      Listing.enables.where(is_full_address: false).where('title regexp ?', '^[0-9]+ ').select(:title, :id).each do |l|
        l.update_column :is_full_address, true
      end
    end

    def fix_status_for_20
      Listing.where(status: 20).where('created_at > ?', Time.now - 7.day).each do |l|
        l.status = 0
        l.save
        l.update_columns status: 21 if l.status == 20
      end
    end

    def clear_building_venue_for_short_address
      Listing.where(is_full_address: false).where.not(building_venue_id: nil).update_all building_venue_id: nil
    end

    def fix_street_number opt = {}
      Listing.enables.where("title regexp '[0-9]+ ' and formatted_address like ? and title not like ?", '%-%', '%-%')
        .where(opt).order(id: :desc).pluck(:id).each do |l_id|
        l = Listing.find l_id
        if l.title =~ /^\d+\s/ && l.title !~ /\d+\s+\d+\s/
          l.is_full_address = true
          l.formatted_address = nil
          l.street_address = nil
          l.reimprove_address
          next if l.formatted_address.blank?
          l.save
        end
      end
    end

    def fix_full_address opt = {}
      Listing.enables.where(is_full_address: false).where(opt)
        .where("title regexp '[0-9]+ '").order(id: :desc).pluck(:id).each do |l_id|
        l = Listing.find l_id
        if l.title =~ /^\d+\s/ && l.title !~ /\d+\s+\d+\s/
          l.is_full_address = true
          if l.formatted_address !~ /^\d+\s/
            l.formatted_address = nil
            l.street_address = nil
            l.reimprove_address
            next if l.formatted_address.blank?
          end
          l.save
        end
      end
    end

    def fix_repeat_listings opt={}
      Listing.where(opt).group(:title, :unit, :beds, :baths, :broker_id).count.keys.each do |vals|
        hash = {title: vals[0], unit: vals[1], beds: vals[2],baths: vals[3], broker_id: vals[4]}
        l = Listing.enables.where(opt).where(hash).last
        if l
          hash[:price] = (l.price - 400)..(l.price + 300)
          Listing.enables.where(opt).where(hash).where.not(id: l.id).update_all status: 32
        end
      end
    end

    def expired_after_7day_custom_listings
      Listing.where.not(account_id: nil).where('updated_at < ?', Time.now - 7.day).update_all status: -1, updated_at: Time.now
    end
  end
end
