class Building < ActiveRecord::Base
  VALID_COLS = { year_built: ->(y) { y && y != '0'}}

  acts_as_mappable

  enum flag: [:csv_sources, :custom]

  has_many :building_mta_lines,  dependent: :destroy
  has_many :building_images, dependent: :destroy
  has_many :building_places, -> { order :distance }, dependent: :destroy
  has_many :reputations, as: :reputable, dependent: :destroy
  accepts_nested_attributes_for :building_images, reject_if: :all_blank, allow_destroy: true
  has_many :floorplans, dependent: :destroy
  accepts_nested_attributes_for :floorplans, reject_if: :all_blank, allow_destroy: true
  belongs_to :political_area

  before_validation :set_building_geo_fields_by_address, on: :create

  has_many :likeables, as: :collection, dependent: :destroy

  validates_presence_of :city, :state, :address, :name, :description
  validates_uniqueness_of :formatted_address

  scope :review_buildings, ->{ where(id: Venue.buildings.pluck(:region_id)) }

  after_create :improve_building, if: ->(building) { building.city == 'NYC' && building.custom? }
  #before_save :set_amenities
  #before_save :set_apt_amenities
  #before_save :set_neighborhood
  before_save :set_building_geo_fields_by_address, if: :check_lat_lng?
  after_save :set_build_mta

  alias_attribute :floors, :num_floors
  alias_attribute :units, :units_total
  alias_method :places, :building_places

  serialize :amenities, Array

  extend FriendlyId
  friendly_id :address, use: :slugged

  # scope :latlngs, -> { where('political_area_id is not null and lat is not null and lng is not null and zipcode is not null') }
  # scope :enables, -> { where("name is not null and address is not null").latlngs }
  scope :enables, -> { where("name is not null and address is not null") }

  include GeoHelper

  NYC_LINECOLORS = [
    [:red, ['1', '2', '3']],
    [:green, ['4', '5', '6']],
    [:blue, ['A', 'C', 'E']],
    [:orange, ['B', 'D', 'F', 'M']],
    [:brown, ['J', 'Z']],
    [:yellow, ['N', 'Q', 'R']],
    [:gray, ['L']],
    [:dark, ['S']]
  ].inject({}){|r, arr|
    h = {}
    arr[1].each do |l|
      h[l] = arr[0]
    end
    r.merge! h
  }


  def self.init_ny_building_from_csv
    require 'csv'
    boros = ['MN', 'BK', 'QN', 'SI', 'BX']
    boros.each do |csv|
      csv = Rails.root.join('db/buildings/nyc', "#{csv}.csv")
      row_i = 0
      keys = []
      CSV.foreach csv do |row|
        if row_i == 0
          keys = row.map(&:underscore)#.select{|s| column_names.include? s.to_s}
        else
          hash = {city: 'NYC', flag: 0}
          keys.each_with_index{|key, i|
            hash[key.to_sym] = row[i] if column_names.include? key
          }
          unless VALID_COLS.keys.any?{|s| !VALID_COLS[s].call(hash[s])}
            unless Building.unscoped.exists?(hash.slice(:city, :borough, :address, :flag))
              Building.unscoped.where(hash.slice(:city, :borough, :address, :flag)).first_or_initialize.update_attributes hash
            end
          end
        end
        row_i += 1
        if row_i % 500 == 0
          p row_i
          p hash
        end
      end
    end
  end

  def self.init_ny_building_from_sql
    require 'zip'
    Dir[Rails.root.join('db/buildings/nyc/*.zip')].each do |zip|
      Zip::File.open(zip) do |z_file|
        z_file.each do |f|
          sql = File.join(File.dirname(zip), f.name)#File.join()
          z_file.extract f, sql  unless File.exist? sql
          config = ActiveRecord::Base.connection_config
          exec_sql = "mysql"
          exec_sql += " -u#{config[:username] || 'root'}" # if config[:username]
          exec_sql += " -p#{config[:password]}" if config[:password]
          exec_sql += " -h #{config[:host]}" if config[:host]
          exec_sql += " #{config[:database]} < #{sql}"
          `#{exec_sql}`
        end
      end
    end
  end

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

  def borough_sub_ids
    if self.city == 'NYC' && self.borough
      areas = PoliticalArea.nyc.sub_areas.where(long_name: Building.nyc_borough_hashes[self.borough.downcase.to_sym])
      areas.map{|s| s.sub_ids(include_self: true)}.flatten.uniq
    end
  end

  def address_translator_url
    AddressTranslator.address_translator_url self.address, borough: self.borough, city: self.city
  end

  def same_addresses
    @same_addresses ||= AddressTranslator.address_translator_same_addresses self.address, borough: self.borough, city: self.city
    @same_addresses
  end

  def same_street_addresses
    AddressTranslator.same_street_addresses same_addresses
  end

  def improve_building
    building = AddressTranslator.get_master_building_by_building self#get_building_from_address same_addresses
    if building
      attrs = building.attributes.reject{|s|['id', 'address'].include? s}
      self.update_columns attrs
    end
  end

  def full_address
  end

  def self.improve_address opt={size: 20000, time_limit: 80000}
    begin_id = 0
    ids = []
    id_size = 0
    opt[:time_limit] ||= 80000
    opt[:size] ||= 20000
    size = opt[:size]
    times = 800000 / opt[:time_limit]
    key = 'building:improve_address:index'
    current_index = $redis.get(key).to_i
    (1..times).each do |page|
      begin_id += opt[:time_limit]
      Building.csv_sources.where(city: 'NYC').where("borough != 'MN'").where('id > ?', current_index)
      .order(:id).page(page)
      .per(opt[:time_limit]).pluck(:id, :address).each do |arr|
        break if id_size > size
        if arr[1] && arr[1].split(/\s/)[1..-1].select{|s| s.size < 4}.size > 0
          ids << arr[0]
          id_size += 1
        end
      end
      break if id_size > size
    end
    $redis.set key, ids.last
    buildings = Building.where(id: ids).select(:borough, :id, :address, :city)
    buildings.each do |building|
      building.improve_address
    end
  end

  #def subway_lines_order_by_color
  #  # order by color  where the listing city is new york
  #  if self.city == 'NYC'
  #    self.subway_lines.sort{|x, y|
  #      x_l = x.icon_url.split('.')[-2].split('_').last
  #      y_l = y.icon_url.split('.')[-2].split('_').last
  #      "#{x.distance_text.split(' ').reverse.join}#{NYC_LINECOLORS[x_l]}" <=> "#{y.distance_text.split(' ').reverse.join}#{NYC_LINECOLORS[y_l]}"
  #    }
  #  else
  #    self.subway_lines
  #  end
  #end

  def geo
    #if self.city == 'NYC'
    #  addr = "#{self.address}, #{Building.nyc_borough_hashes[self.borough.downcase.to_sym]}, NY, USA"
    #else
    addr = "#{self.address}"
    #addr << ", #{self.borough}" if self.borough
    addr << ", #{self.city}"
    addr << ", #{self.state}"
    addr << ", USA"
    #end
    do_geocode(addr)
  end

  def improve_address
    geo = self.geo
    if geo.success? && geo.place_types.include?('street_address') && geo.street_address
      others = Building.custom.where(city: self.city, borough: self.borough, address: geo.street_address)
      Venue.where(region: others).update_all region_id: self.id
      others.destroy_all
      self.update_columns address: geo.street_address
    end
  end

  def set_amenities
    if self.amenities.present? && String === self.amenities
      self.amenities = self.amenities.split(',').map(&:strip)
    else
      self.amenities = []
    end
  end
  private :set_amenities


  def set_relate_listings
    if self.borough && self.city == 'NYC'
      same_street_addresses.each do |st|
        lls = Listing.where(political_area_id: borough_sub_ids, is_full_address: true)
        while m = st.match(/\s(\d+)\s/)
          st.sub!(m[0], " #{m[1]}% ")
        end
        lls = lls.where('formatted_address like ?', "#{st}%")
        lls.each do |l|
          building_listings.where(listing: l).first_or_create
        end
      end
    end
  end

  def set_building_geo_fields_by_address
    geo = self.geo
    if geo.success?
      set_latlng geo
      set_zipcode geo
      set_political_area geo
    end
  end

  def set_build_mta
    MapsServices::RetrieveBuildingMtaLine.setup self
  end

  def set_latlng geo
    #self.update_attributes(lat: geo.lat, lng: geo.lng)
    self.lat, self.lng = geo.lat, geo.lng
  end

  def set_zipcode geo
    #self.update_attribute(zipcode: geo.zip)
    self.zipcode = geo.zip
    self.formatted_address = geo.full_address
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

  def closest_listing
    result = nil
    Listing.where("abs(lat - ?) < 0.002 AND abs(lng - ?) < 0.002",self.lat,self.lng).first(10).each do |listing|
      if !listing.transport_distances.empty?
        result = listing
        break
      end
    end
    result
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

  def subway_lines
    @subway_lines ||=begin
                       lines = building_mta_lines.where(target: 'subway').where('building_mta_lines.distance < ?', 1200).to_a.uniq{|s| s.mta_info_line_id}
                       if lines.blank?
                         building_mta_lines.where(target: 'subway').to_a.uniq{|s| s.mta_info_line_id}
                       else
                         lines
                       end
                     end
  end

  def subway_lines_order_by_color
    if self.city == 'NYC'
      self.subway_lines.sort{|x, y|
        x_l = x.icon_url.split('.')[-2].split('_').last
        y_l = y.icon_url.split('.')[-2].split('_').last
        "#{x.distance_text.split(' ').reverse.join}#{NYC_LINECOLORS[x_l]}" <=> "#{y.distance_text.split(' ').reverse.join}#{NYC_LINECOLORS[y_l]}"
      }
    else
      self.subway_lines
    end
  end

  class << self
    def boroughs
      @@borough ||= Building.where("borough is not null").distinct(:borough).select(:borough).pluck(:borough).flatten
    end
    def cities
      @@cities ||= Building.where("borough is not null").distinct(:city).select(:city).pluck(:city).flatten
    end
  end

  def price
    self.floorplans.map(&:price).min
  end

  def build_collect_by(account)
    if account
      self.reputations.where(category: 'building', account_id: account_id).first_or_create
    end
  end

  def build_uncollect_by(account)
    if account
      self.reputations.where(category: 'building', account_id: account_id).destroy_all
    end
  end

  private

  def check_lat_lng?
    lat.nil? || lng.nil?
  end
end
