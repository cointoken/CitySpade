module ReviewHelper
  include GeoHelper
  extend ActiveSupport::Concern
  ## auto set venue
  def set_venue_info(flag = true)
    if self.formatted_address.present?
      venue_was = self.venue
      if self.is_neighborhood?
        venues = Venue.street_neighborhoods
      else
        venues = Venue.buildings
      end
      #v = venues.where(formatted_address: self.formatted_address).first
      v = venues.where(
        'formatted_address = ? or formatted_address like ? or formatted_address like ?',
        self.formatted_address, self.geo_like_address, self.geo_full_word_address).first
      if v
        self.venue = v
      else
        @new_venue_flag = true
        attr_names = self.rating_stars + ['full_address', 'lat', 'lng', 'political_area_id']
        attr_names << 'overall_quality' if Venue.column_names.include? 'overall_quality'
        set_political_area
        new_venue = venues.create(attributes.slice(*attr_names))
        self.venue_id = new_venue.id
        find_and_match_listings
      end
      self.update_columns venue_id: self.venue.id if flag
      self.venue && (!@new_venue_flag && self.venue.set_ratings_hook(true, self.id))
      venue_was.set_ratings_hook(true, self.id) if venue_was && self.venue != venue_was
    end
  end
 
  def set_political_area
    neighborhood = do_geocode(self.formatted_address).long_neighborhood
    self.political_area_id = PoliticalArea.where('long_name like ?', "#{neighborhood}").first.id
  end

  def find_and_match_listings
    if self.geo_like_address.size > 15
       Listing.where(building_venue_id: nil, is_full_address: true).where(
         'formatted_address = ? or formatted_address like ? or formatted_address like ?', 
         self.formatted_address, self.geo_like_address, self.geo_full_word_address)
         .update_all building_venue_id: self.venue.id
    end
  end
  
  def has_places?
    self.laundries.present? && self.laundries.any?{|s| s.name.present?} or
      self.groceries.present? && self.groceries.any?{|s| s.name.present?}
  end

  def has_rating_change?
    (self.rating_stars  + ['overall_quality']).any?{|col| self.changed.include? col}
  end

  def reset_venue_ratings(reflag = false)
    (!@new_venue_flag || reflag) && (self.venue_id && self.venue.set_ratings_hook(true, self.id))
  end

  def set_status_for_instance
    if has_rating_change? || self.status != self.status_was ||
        self.formatted_address != self.formatted_address_was
      @rating_changed = true
    end

    @address_change = true if changed.any?{|s| ['address', 'city', 'state', 'cross_street'].include? s}
    # if changed.any?{|col| ['address', 'lat,']}
  end

  def reset_strong_word_after_update
    strongs = Nokogiri::HTML(self.comment_was).css('b').map{|s| s.text.strip}.reject(&:blank?)
    if strongs.present?
      strongs.each do |strong|
        self.comment.gsub!(strong, "<b>#{strong}</b>")
      end
    end
  end

  def round_rating(target = :overall_quality)
    rating = send(target)
    if rating #&& rating
      ((rating * 2 + 0.5).floor / 2.0)
    end
  end


  module ClassMethods
    def search(address, current_city, opts={})
      reviews = Review.enable_venues.includes_account.distinct_venues
      #@reviews = Review.where(city: params[:location].split(',').first)  if params[:location]
      query = (address || '').strip.split(',')
      # delete building name
      bld_name = query.delete_at 0 if query.size > 3
      bld_name ||= query[0]
      bld_name = nil if bld_name !~ /^[A-z]/
      if query[1..-1].present?
        reviews = search_reviews_decorator_address(query[1..-1], reviews)
      end
      q = query[0] || ''
      # delete building name, eg: Trump Place - 140 Riverside Boulevard
      q = q.split('-').last.strip if q.split('-').first =~ /^\D/
      if query =~ /^\d{5}$/
        return reviews.where(zipcode: query).order_by_rating(current_city)
      end
      if q.present?
        q.gsub!(/^w\s/i, "West ")
        q.gsub!(/\sw\s/i, " West ")
        q.gsub!(/\se\s/i, " East ")
        q.gsub!(/^e\s/i, "East ")
        if current_city.political_state
          area = current_city.political_state.sub_areas.where("long_name = :q or short_name = :q", q: q)
          if area.present?
            ids = area.map{|a| a.sub_areas(include_self: true).map{|s| s.id}}.flatten
            reviews = reviews.where(political_area_id: ids)
          else
            if bld_name
              reviews = reviews.where('address like :q or full_address like :q or building_name like :q or cross_street like :q or building_name like :bld', q: "%#{q}%", bld: "#{bld_name}")
            else
              reviews = reviews.where('address like :q or full_address like :q or building_name like :q or cross_street like :q', q: "%#{q}%")
            end
          end
        else
          if bld_name
            reviews = reviews.where('address like :q or full_address like :q or building_name like :q or cross_street like :q or building_name like :bld', q: "%#{q}%", bld: "#{bld_name}")
          else
            reviews = reviews.where('address like :q or full_address like :q or building_name like :q or cross_street like :q', q: "%#{q}%")
          end
        end
      end

      if opts[:lat] && opts[:lng]
        opts[:lat] = opts[:lat].to_f
        opts[:lng] = opts[:lng].to_f
        reviews = reviews.order("power(reviews.lat - #{opts[:lat]}, 2) + power(reviews.lng - #{opts[:lng]}, 2)")
        reviews = reviews.within(10, units: :kms, origin: [opts[:lat], opts[:lng]])
      end
      reviews = reviews.order_by_rating(current_city)
      if reviews.blank? && q.present?
        geo_address = "#{q}, #{query[1] || current_city.name}, #{query[2] || current_city.state}"
        geo = $geocoder.geocode(geo_address)
        if geo.success?
          reviews = Review.enable_venues.includes_account.distinct_venues.order("abs(reviews.lat - #{geo.lat}) + abs(reviews.lng - #{geo.lng})")
        end
      end
      reviews
    end

    def search_reviews_decorator_address addrs, results
      reviews = results || Review.all
      all_areas = []
      all_zipcode = []
      addrs.each do |addr|
        addr.strip!
        if addr =~ /^\d{5}$/
          all_zipcode << addr
        else
          areas = PoliticalArea.where('long_name = :q or short_name = :q', q: addr)
          if areas.present?
            all_areas << areas.map{|area|area.sub_ids(include_self: true)}.flatten
          end
        end
      end
      if all_zipcode.present?
        reviews = reviews.where(zipcode: all_zipcode)
      end
      if all_areas.present?
        reviews = reviews.where(political_area_id: all_areas.flatten.uniq)
      end
      reviews
    end

    def created_by_ip?(ip)
      Review.exists?(ip: ip)
    end
  end
end
