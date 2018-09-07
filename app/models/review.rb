class Review < ActiveRecord::Base
  acts_as_mappable
  REVIEW_TYPE = {'apartment-build' => 0, 'street-neighborhood' => 1}

  attr_accessor :address_change
  attr_reader :rating_changed
  cattr_writer :lastest_id
  include GeoHelper
  include ReviewHelper

  belongs_to :account
  belongs_to :political_area
  belongs_to :venue
  has_many :review_places, dependent: :destroy
  has_many :reputations, as: :reputable, dependent: :destroy
  has_many :photos, as: :imageable, dependent: :destroy
  has_many :page_views, as: :page, dependent: :destroy
  has_one :disqus, as: :disqus_obj, dependent: :destroy
  has_one :review_apartment
  has_one :review_street

  alias_method :images, :photos
  alias_attribute :formatted_address, :full_address

  delegate :groceries, :to => :review_places
  delegate :laundries, :to => :review_places
  delegate :master_venue , :to => :venue

  #default_scope -> { where('account_id is not null and status = 1') }
  default_scope -> { where(status: true) }
  scope :enable_venues, -> { where('reviews.venue_id is not null and reviews.full_address is not null')}
  scope :includes_account, -> { includes(:account) }
  scope :distinct_venues, -> {
    where("reviews.id = (select r2.id from reviews as r2 where r2.venue_id = reviews.venue_id and status=1 order by r2.id desc limit 1)")
  }
  scope :buildings, -> { where(review_type: 0) }
  scope :neighborhoods, -> { where(review_type: 1) }

  before_save :set_status_for_instance, if: ->(review) { review.changed.present? }
  before_save :improve_address, if: ->(review) { review.address_change }
  before_save :reset_strong_word_after_update, if: ->(review) { !review.new_record? &&
                                                                review.comment != review.comment_was &&
                                                                review.comment_was.include?('<b>')
  }

  before_save :check_is_complete
  after_save :set_venue_info, if: ->(review) { review.address_change || review.venue.blank? }
  after_save :reset_venue_ratings, if: ->(review) { review.venue && review.rating_changed }
  after_save :reset_venue_reviews_count

  after_destroy :reset_venue_ratings, if: ->(review) { review.venue.present? }
  # after_save :set_lastest_id

  scope :expired, -> { unscoped.where(status: 0)}
  scope :recents, -> { order('created_at desc') }
  scope :hots, -> { order('hot desc, id desc') }
  scope :order_by_rating, ->(city) { order(Review.order_by_rating_sql(city)) }
  scope :order_by_time, ->(city) { order(Review.order_by_time_sql(city))}
  accepts_nested_attributes_for :photos, allow_destroy: true
  accepts_nested_attributes_for :review_places, allow_destroy: true,  reject_if: proc { |attributes| attributes['comment'].blank? }

  validates_inclusion_of :review_type, in: REVIEW_TYPE.values
  validates_presence_of :review_type, :address

  # collect review by self in controller
  # after_create :set_first_collect

  alias_method :images, :photos

  paginates_per 8

  def relative_listings(opt={kms: 2})
    # 查找附近1公里内的相关信息
    similar_listings = Listing.enables.rentals.where(is_full_address: true)
      .where('listing_image_id is not null')
    similar_listings = similar_listings.order("formatted_address like \"#{self.full_address.split(',').first}%\" desc")
    similar_listings = similar_listings.order("FORMAT((abs(listings.lat - #{self.lat}) + abs(listings.lng - #{self.lng})) / 3, 3)").order('score_price + score_transport desc')
    similar_listings.limit 12
    # where(political_area_id: self.political_area.borough.sub_ids(include_self: true)).limit 12
  end

  def self.lastest_id
    @@lastest_id ||= Review.order(updated_at: :desc).select(:updated_at).first.updated_at.to_i
  end

  def update_columns attrs
    set_lastest_id
    super attrs
  end

  def set_lastest_id
    Review.lastest_id = Time.now.to_i
  end

  def set_expired
    self.status = 0
    self.save
  end

  def is_expired?
    self.status == false || self.status == 0
  end

  def is_enable?
    !is_expired?
  end

  def account_avatar_url(size = '55')
    if self.account
      unless self.account.origin_image_url.include?('user_icon')
        return self.account.origin_image_url
      end
    end
    if self.id
      img_id =  (self.id % 4) + 1
    else
      img_id  = 1
    end
    "reviews/avatars/0#{img_id}_#{size}.png"
  end

  def img_title(index = nil)
    index ? "#{self.title}-#{index + 1}" : self.title
  end

  def display_name
    return read_attribute('display_name') if new_record?
    read_attribute('display_name') || begin
    if account
      account.name
    else
      'Guest'
    end
    end
  end

  def average_overall_quality
    venue.try(:overall_quality) || overall_quality
  end

  def address_images
    @address_images ||= begin
                          if self.is_neighborhood?
                            images
                          else
                            if self.full_address.blank?
                              images
                            else
                              venue ? venue.images : begin
                                                       reviews = Review.where(full_address: self.full_address)
                                                       Photo.where(imageable_type: 'Review', imageable_id: reviews.map(&:id)).order(id: :desc)
                              end
                            end
                          end
                        end
  end

  def check_is_complete update_flag = false
    if self.city.present? and self.state.present? and self.address.present?
      if self.full_address.blank?
        # self.update_column(:complete, false)
        self.complete = false
      elsif self.full_address.split(",").size != 3
        if (self.review_type == 1 and self.building_name.present? ) or self.review_type == 0
          # self.update_column(:complete, true)
          self.complete = true
        else
          # self.update_column(:complete, false)
          self.complete = false
        end
      else
        # self.update_column(:complete, false)
        self.complete = false
      end
    else
      # self.update_column(:complete, false)
      self.complete = false
    end
    self.update_column complete: self.complete if update_flag
  end

  class << self
    def order_by_rating_sql(city)
      # if use sqlite need return random() function
      #return "random()"
      str1 = "(10 * (LOG2(5 * (reviews.collect_num) + 1.5)))"
      str = "(TO_DAYS(current_date)-TO_DAYS(date(reviews.created_at))) * 24 + hour(current_time) - hour(reviews.created_at)"
      str += "+ (minute(current_time) - minute(reviews.created_at)) / 60.0 + 1"
      "reviews.city='#{city.name}' desc, reviews.state= '#{city.state}' desc,#{str1} / (pow(abs((#{str}) / 3), 1/3)) desc, reviews.id desc"
    end

    def order_by_time_sql(city)
      "city = '#{city.name}' desc, state='#{city.state}' desc, reviews.id desc"
    end

    def clear_expired_images(opt = {})
      return unless respond_to?(:expired)
      expired.where('updated_at < ?', Time.now - 7.day).where(opt).each do |obj|
        obj.images.destroy_all
      end
    end
  end

  def full_neighborhood
    "#{self.political_area.try(:long_name)}, #{state.upcase}, #{self.zipcode}"
  end

  def is_neighborhood?
    self.review_type != 0
  end

  def to_param
    #{id: self.id, review_type: 'building', permalink: self.formatted_address.to_url}
    # "buildings-#{self.formatted_address.to_url}-#{self.id}"
    "#{self.id} #{self.title}".to_url
  end

  def venue_param
    {id: self.id, permalink: self.venue.formatted_address.to_url, review_type: self.review_type_short_name}
  end

  def listing_venue_param(listing_id)
    {id: self.id, permalink: self.formatted_address.to_url, review_type: self.review_type_short_name, listing_id: listing_id}
  end

  def review_type_short_name
    is_neighborhood? ? 'street_neighborhoods' : 'buildings'
  end

  def rating_stars
    if self.review_type == 0
      ['building', 'management', 'safety', 'convenience', 'things_to_do']
    else
      ['ground', 'quietness', 'safety', 'convenience', 'things_to_do']
    end
  end

  def collect_by(account)
    if account
      self.reputations.where(category: 'collect', account_id: account.id).first_or_create
    end
  end

  def uncollect_by(account)
    if account
      self.reputations.where(category: 'collect', account_id: account.id).destroy_all
    end
  end

  def real_address
    self.venue.try(:address) || self.address
  end
  def real_building_name
    self.venue.try(:building_name) || self.building_name
  end

  def title
    return @title if @title.present?
    if self.is_neighborhood?
      titles = []
      unless self.real_building_name.present? && self.cross_street.present?
        titles << self.real_building_name if self.real_building_name && !self.real_address.downcase.include?(self.real_building_name.downcase)
        titles << self.cross_street if self.cross_street && !self.real_address.downcase.include?(self.cross_street.downcase)
      end
      titles << self.real_address
      titles << self.political_area.short_name if self.political_area.try(:short_name) && !self.real_address.downcase.include?(self.political_area.short_name.downcase)
      @title = titles.join(', ')
    else
      @title = self.real_address
      @title = "#{self.real_building_name}, #{@title}" if self.real_building_name.present?
      @title = "#{@title}, #{self.political_area.short_name}" if self.political_area.try(:short_name).present?
    end
    @title
  end

  def review_type_name
    self.review_type == 0 ? 'Apartment/Building' : 'Street/Neighborhood'
  end

  def auto_build_info(all_flag = false)
    self.review_places.build
  end

  def og_type
    is_neighborhood? ? "cityspade:neighborhood" : "cityspade:building"
  end

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64
      break random_token unless Review.where(token: random_token).exists?
    end
  end

  def set_first_collect
    if self.account.present? && self.reputations.where(category: 'collect', account_id: self.account.id).first.blank?
      self.reputations.where(category: 'collect', account_id: self.account.id).create
    end
  end

  def location
    "#{city}, #{state}"
  end
  # usage mysql query cal the rating  for begin
  #include Ranking
  #  def set_hot
  #ups = self.reputations.count + self.review_replies.count * 10
  #self.hot = cal_hot(ups, 0, self.created_at)
  #self.save
  #end
  class << self
    def init_hot
      all.each do |review|
        review.set_hot
      end
    end

    def has_review_in_city?(city)
      where(city: city.name, state: city.state).first.present?
    end

    def init_improve_address
      unscoped.all.each do |review|
        review.improve_address true
      end
    end
  end

  def city_obj
    City.where(state: self.state, name: self.city).first
  end

  def improve_address(update_flag = false)
    # @address_change = true
    g_address = self.address
    opt = {key: Settings.google_maps.server_keys.sample}
    if self.is_neighborhood?
      if self.building_name.present? && self.cross_street.present?
        g_address = "#{self.cross_street} and #{self.building_name}, #{g_address}"
      else
        g_address = "#{self.building_name}, #{g_address}" if self.building_name.present?
        g_address = "#{self.cross_street}, #{g_address}" if self.cross_street.present?
      end
    end
    g_address = "#{g_address}, #{self.city}" if self.city.present?
    g_address = "#{g_address}, #{self.state}" if self.state.present?
    geo = do_geocode(g_address, opt)
    if geo.success
      self.lat = geo.lat
      self.lng = geo.lng
      self.zipcode = geo.zip
      self.full_address = geo.full_address
    else
      g_address = self.address
      g_address = "#{g_address}, #{self.city}" if self.city.present?
      g_address = "#{g_address}, #{self.state}" if self.state.present?
      geo = do_geocode(g_address, opt)
      if geo.success
        self.lat = geo.lat
        self.lng = geo.lng
        self.zipcode = geo.zip
        self.full_address = geo.full_address
      else
        return
      end
    end
    if self.political_area.blank? || (self.lat != self.lat_was || self.lng != self.lng_was)
      get_neighborhood_flag = false
      if is_neighborhood? && city_obj
        p_area =  city_obj.political_city.sub_areas.where("long_name = ? or short_name = ?", self.address, self.address).first
        if p_area
          get_neighborhood_flag = true
          self.political_area = p_area
        end
      end
      unless get_neighborhood_flag
        latlng = Geokit::LatLng.new self.lat, self.lng
        geo = do_reverse_geocode(latlng)
        if geo.success
          self.political_area = PoliticalArea.retrieve_from_address_compontents(geo.full_political_areas)
        end
      end
    end
    #self.geocoding_flag = true
    self.update_columns(lat: self.lat, lng: self.lng, political_area_id: self.political_area_id,
                        full_address: self.full_address, zipcode: self.zipcode) if update_flag #save
    #self.geocoding_flag = false
  end

  def reset_venue_reviews_count
    if self.venue_id.present?
      v = Venue.find(self.venue_id)
      now_count = v.reviews_count.to_i
      v.update_column(:reviews_count, now_count)
    end
  end
end
