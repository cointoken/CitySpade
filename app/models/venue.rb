class Venue < ActiveRecord::Base

  RATING_COLS = [:building, :management, :safety, :convenience, :things_to_do, :ground, :quietness, :overall_quality] & Venue.column_names.map(&:to_sym)

  validates_uniqueness_of :permalink, scope: :region_type, if: ->(venue) { !venue.only_venue_flag }
  validates_presence_of :permalink, :region_type, :political_area_id, if: ->(venue){ !venue.only_venue_flag }

  include GeoHelper

  has_many :reviews
  has_many :photos, as: :imageable
  belongs_to :region, polymorphic: true
  belongs_to :political_area
  belongs_to :parent, class_name: self, foreign_key: :parent_id
  has_many :children, class_name: self, foreign_key: :parent_id

  scope :order_by_most_reviews, -> { order(reviews_count: :desc, overall_quality: :desc) }
  scope :buildings, -> { where(region_type: 'Building') }
  scope :street_neighborhoods, -> { where(region_type: 'StreetNeighborhood') }
  scope :order_by_overall_quality, -> { order(overall_quality: :desc).order(id: :desc) }
  scope :only_venus, -> { where only_venue_flag: true }

  before_validation :set_permalink
  after_create :set_region_hook, :set_reviews_count
  before_create :set_ratings_hook, if: ->(venue) { venue.only_venue_flag}

  alias_attribute :full_address, :formatted_address

  # delegate :year_built, :floors, :units, to: :region, allow_nil: true
  delegate :city, :rel_sub_area_ids, to: :political_area

  [:year_built, :floors, :units].each_with_index do |col, index|
    class_eval <<-ATTR_METHODS, __FILE__, __LINE__ + 1
      def #{col}
        if region
          region.send('#{col}') || 'N/A'
        else
          'N/A'
        end
      end
    ATTR_METHODS
  end

  def master_venue
    building? ? self : (self.parent || self)
  end

  def all_children_ids
    @all_ids ||= begin
                   all_ids = []
                   children.each do |child|
                     all_ids << child.id
                     all_ids << child.all_children_ids if child.parent_id
                   end
                   all_ids.flatten
                 end
  end

  def all_children
    @all_children ||= Venue.where id: all_children_ids
  end

  def all_reviews(current_id = nil)
    if building?
      all_r = reviews
    else
      all_r = Review.neighborhoods.where(political_area_id: rel_sub_area_ids(include_self: true))
    end
    if current_id
      all_r = all_r.order("id = #{current_id} desc")
    end
    all_r.order(id: :desc)
  end

  def reviews_count
    @reviews_count ||= all_reviews.size
  end

  def rel_reviews
    building? ? all_reviews : Review.where(political_area_id: rel_sub_area_ids(include_self: true))
  end

  def rel_neighborhood_venues
    Venue.street_neighborhoods.where(political_area_id: rel_sub_area_ids(include_self: true))
  end

  def building_reviews
    if building?
      reviews
    else
      Review.buildings.where(political_area_id: rel_sub_area_ids(include_self: true))
    end
  end

  def neighborhood_reviews
    Review.neighborhoods.where(political_area_id: rel_sub_area_ids(include_self: true))
  end


  def listings
    Listing.where(political_area_id: rel_sub_area_ids(include_self: true))
  end

  def listings_size
    listings.enables.rentals.size
  end

  def access_listing?
    PoliticalArea.all_city_sub_area_ids.include? self.political_area_id
  end

  def set_parent reflag = false
    unless building?
      ## real_area => get real political area by name
      if self.only_venue_flag
        if self.political_area.real_area.parent.real_area.is_neighborhood?
          self.update_columns parent_id: Venue.street_neighborhoods
            .where(only_venue_flag: true, political_area_id: self.political_area.real_area.parent.real_area.id)
            .first_or_create.id
        end
      else
        if parent.blank? || reflag# && political_area.parent.is_neighborhood?
          self.update_columns parent_id: Venue.street_neighborhoods
            .where(only_venue_flag: true, political_area_id: self.political_area.real_area.id)
            .first_or_create.id
        end
      end
      pv = self.parent
      while pv
        pv.set_ratings true
        pv = pv.parent
      end
    end
  end

  def parent_ids opt={}
    arr = []
    arr << self.id if opt[:include_self]
    pt = self.parent
    while pt
      arr << pt.id
      pt = pt.parent
    end
    arr
  end

  def landmark
    "Building in #{political_area.long_name}"
  end

  def address
    @address ||= formatted_address.split(',').first
  end

  def reviews_count
    read_attribute(:reviews_count).to_i == 0 ? 1 : read_attribute(:reviews_count)
  end

  def collect_num
    Reputation.where(reputable_id: reviews.pluck(:id), reputable_type: 'Review').size
  end

  def building?
    self.region_type == 'Building'
  end

  def review_param
    {review_type: self.region_type.underscore.pluralize, permalink: self.permalink}
  end

  def building_name
    if building?
      region.try(:name).present? ? region.name : nil
    end
  end

  def set_permalink
    if (self.changed.include?('formatted_address') || self.permalink.blank?) && self.formatted_address
      self.permalink = self.formatted_address.to_url
    end
  end

  def set_reviews_count
    self.reviews_count = self.all_reviews.count
  end

  def images
    Photo.where("(imageable_type = ? and imageable_id = ?) or (imageable_type = ? and imageable_id in (#{(all_reviews.map(&:id) << -1).join(',')}))",
                'Venue', self.id, 'Review').order(id: :desc)
  end

  def ny_shorter_boroughs
    {
      'Manhattan' => 'MN',
      'Brooklyn'  => 'BK',
      'Queens'    => 'QN',
      'Bronx'     => 'BX',
      'Staten Island' => 'SI'
    }
  end

  def get_address_of_formatted_address
    self.geo_street_address.split(/\#|\,/).first #.sub(/(\s\d+[a-z]+\s)/i){" #{$1.remove(/\D/)} "}#, $1 ? " " : '')
  end

  def set_region_hook(flag = true)
    if Rails.env.development?
      set_region flag
    else
      ReviewWorker.perform_async(self.id, :create_venue)
    end
  end

  def set_ratings_hook(flag = false, review_id = nil)
    if Rails.env.development?
      set_ratings flag
    else
      ReviewWorker.perform_async(self.id, :update_ratings, review_id = nil)
    end
  end

  def set_region(flag = false)
    if self.region_type == 'Building'
      ## new york building
      #if self.political_area.city.long_name == 'New York'
      city = self.political_area.city.try(:long_name)
      city = 'NYC' if city == 'New York'

      hash = {city: city, borough: ny_shorter_boroughs[political_area.borough.try(:long_name)], address: get_address_of_formatted_address}
      if city == 'NYC'
        building = Building.csv_sources.where(hash).first ||
          AddressTranslator.find_building_from_address_translator(get_address_of_formatted_address, city: city, borough: ny_shorter_boroughs[political_area.borough.try(:long_name)]) ||
          Building.custom.where(hash).first_or_create
      else
        building = Building.csv_sources.where(hash).first || Building.custom.where(hash).first_or_create
      end
      self.region = building #Building.csv_sources.where(hash).first || Building.custom.where(hash).first_or_create
      self.update_columns region_id: region.id if flag && self.region
      #end
    else
      self.set_parent true
    end
  end
  def set_ratings(flag = false)
    hash = {}
    rel_ratings = [:safety, :convenience, :things_to_do]
    RATING_COLS.each do |col|
      if rel_ratings.include? col
        hash[col] = rel_reviews.average("Floor(#{col})")
      else
        hash[col] = all_reviews.average("Floor(#{col})")
      end
      ## 4.22 => 4.2, 4.37 => 4.4
      hash[col] = hash[col].round(1) if hash[col]
    end
    # update reviews count
    hash[:reviews_count] = all_reviews.count
    if flag
      update_attributes hash
    else
      hash.each{|k, v| send("#{k}=", v)}
    end
  end

  ## 4.2 => 4.0, 4.3 => 4.5
  def round_rating(target = :overall_quality)
    rating = send(target)
    if rating #&& rating
      ((rating * 2 + 0.5).floor / 2.0)
    end
  end

  class << self
    def binding_listings
      Venue.buildings.each do |venue|
        if venue.reviews.count > 0
          Listing.enables.where(building_venue_id: nil).where(formatted_address: venue.formatted_address).update_all building_venue_id: venue.id
        end
      end
    end
  end
end
