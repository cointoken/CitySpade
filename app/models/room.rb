class Room < ActiveRecord::Base
  enum status: %w(active expired)
  belongs_to :account
  belongs_to :political_area
  has_one :room_detail, dependent: :destroy
  has_many :photos, as: :imageable, dependent: :destroy
  has_many :reputations, as: :reputable, dependent: :destroy
  accepts_nested_attributes_for :room_detail
  validate :date_validation
  validate :correct_number_of_rooms

  validates_presence_of :title,
    :available_begin_at,
    :available_end_at,
    :bedrooms,
    :price_month,
    :rooms_available

  validates :photos, presence: {message: "are required"}

  before_save :improve_address, if: ->(sb) {sb.changed?}
  include GeoHelper

  delegate :state, :city, :borough, to: :political_area, allow_nil: true

  def improve_address opt = {}
    if self.political_area.blank? || self.changed.include?('street_address')
      full_address = self.street_address.dup
      ct_zip = [self.city, self.zipcode].select{|s| s.present?}
      if ct_zip.present?
        full_address << ", #{ct_zip.join(' ')}"
      end
      full_address << ', USA'
      opt = {key: Settings.google_maps.server_keys.sample}
      geo = do_geocode(full_address, opt)
      if geo.success
        self.formatted_address = geo.full_address
        self.lat               = geo.lat
        self.lng               = geo.lng
      else
        return
      end
      if self.lat && self.lng
        latlng = Geokit::LatLng.new self.lat, self.lng
        geo = do_reverse_geocode latlng, opt
        if geo.success
          self.political_area = PoliticalArea.retrieve_from_address_compontents geo.full_political_areas
        end
      end
    end
  end

  def real_neighborhood(target = :long)
    long_name = political_area.try(:long_name) || read_attribute(:raw_neighborhood)
    if long_name && target != :long
      long_name = long_name.split('/').first.strip
    end
    long_name
  end

  def img_alt(i = nil)
    img_alt_str = "#{self.street_address}, #{self.political_area.try :long_name}, #{self.city.try :long_name}, #{self.state.try :short_name}"
    if i
      img_alt_str += ", #{i}"
    end
    img_alt_str
  end

  def self.sort_by_created
    active.sort{ |a,b| b.created_at <=> a.created_at }
  end

  def closest_listing
    listing = nil
    Listing.where("lat BETWEEN ? AND ?", lat - 0.001, lat + 0.001).where("lng BETWEEN ? AND ?", lng - 0.01, lng+ 0.01).each do |has|
      if !has.subway_lines.empty?
        listing = has
        break
      end
    end
    listing
  end

  def date_validation
    if available_end_at < available_begin_at
      errors.add(:available_end_at, "cannot be before begin date")
    end
  end

  def correct_number_of_rooms
    # A studio (0 bedrooms) can have one room
    bedrooms == 0 ? corrected_bedrooms = 1 : corrected_bedrooms = bedrooms

    not_enough_bedrooms = (rooms_available > corrected_bedrooms)
    incorrect_rooms_available = (rooms_available < 1) || (rooms_available > 4)
    incorrect_bedrooms = (bedrooms < 0) || (bedrooms > 4)

    if not_enough_bedrooms || incorrect_rooms_available || incorrect_bedrooms
      errors.add(:rooms_available, "must be correct")
    end
  end

  def to_param
    "#{id}-#{clean_url}"
  end

  def clean_url
    title.downcase.gsub(/[^0-9a-z ]/i, '').gsub(" ", "-")
  end
end
