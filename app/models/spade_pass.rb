class SpadePass < ActiveRecord::Base
  belongs_to :political_area
  belongs_to :account

  has_many :spade_pass_images, dependent: :destroy
  has_many :likeables, :as => :collection, :dependent => :destroy
  accepts_nested_attributes_for :spade_pass_images, reject_if: :all_blank, allow_destroy: true

  validates_format_of :zipcode, with: /\A\d{5}\Z/, allow_nil: true

  include GeoHelper

  before_save :set_spade_pass_geo_fields_by_address

  CITY_ARRAY = [
    'New York',
    'Chicago',
    'Boston',
    'Texas',
    'EastCoast',
    'California'
  ]

  def self.nyc_boroughs
    ['mn', 'bx', 'bk', 'qn', 'si']
  end

  def self.nyc_borough_hashes
    {
      mn: 'Manhattan',
      bx: 'Bronx',
      bk: 'Brooklyn',
      qn: 'Queens',
      si: 'Staten Island'
    }
  end

  def geo
    if self.city == 'NYC'
      addr = "#{self.street_address}, #{SpadePass.nyc_borough_hashes[self.borough.downcase.to_sym]}, NY, USA"
    else
      addr = "#{self.street_address}"
      addr << ", #{self.borough}" if self.borough
      addr << ", #{self.borough}" if self.try(:city)
      addr << ", USA"
    end
    do_geocode(addr)
  end

  def set_spade_pass_geo_fields_by_address
    if self.street_address.present?
      geo = self.geo
      if geo.success?
        set_latlng geo
        set_zipcode geo
        set_political_area geo
        set_city geo
      end
    end
  end

  def set_latlng geo
    self.lat, self.lng = geo.lat, geo.lng
  end

  def set_zipcode geo
    self.zipcode = geo.zip
    self.formatted_address = geo.full_address
  end

  def set_city geo
    full_address_array = geo.full_address.split(",")
    if full_address_array.present?
      self.city = full_address_array[1].strip
    end
  end

  def set_political_area geo
    if self.political_area.blank?
      key = Settings.google_maps.server_keys.sample
      latlng = Geokit::LatLng.new(geo.lat, geo.lng)
      re_geo = do_reverse_geocode(latlng, key: key)
      if re_geo.success
        self.political_area = PoliticalArea.retrieve_from_address_compontents(re_geo.full_political_areas) || self.political_area
      end
    end
  end

  def special_offers_array
    self.special_offers.try(:split, /[，|,]/)
  end

  def author_name
    self.account.name
  end

  def cover_image
    cover_img = self.spade_pass_images.where(cover: true).first
    cover_img.blank? ? self.spade_pass_images.first : cover_img
  end

  def discounts_expired_formatted_date
    self.discounts_expired_date.try(:strftime, '%Y-%m-%d')
  end

  class << self
    def boroughs
      @@borough ||= SpadePass.where("borough is not null").distinct(:borough).select(:borough).pluck(:borough).flatten
      if @@borough.blank?
        @@borough = ["", self.nyc_boroughs].flatten
      end
    end
    def cities
      @@cities ||= SpadePass.where("borough is not null").distinct(:city).select(:city).pluck(:city).flatten
    end
  end

end
