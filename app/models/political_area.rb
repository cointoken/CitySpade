class PoliticalArea < ActiveRecord::Base
  acts_as_nested_set
  include BoundaryHelper
  include GeoHelper

  cattr_accessor :neighborhoods
  @@neighborhoods = {}
  has_many :listings, dependent: :destroy
  has_many :buildings, dependent: :destroy
  has_many :transport_places
  has_many :reviews
  has_many :venues
  has_many :spade_passes
  before_create :set_latlng
  before_save :set_permalink

  default_scope -> { where enabled: true }

  # default_scope -> { select(:id, :short_name, :long_name, :target, :parent_id, :lft, :rgt, :depth, :lat, :lng) }
  scope :states, -> { where(target: 'administrative_area_level_1') }
  scope :neighborhood, -> { where(target: 'neighborhood') }
  scope :cities, -> { where("target like ?", 'locality%') }
  scope :sub_cities, -> { where("target like ?", 'sublocal%') }

  #  searchable do
  #string :long_name, :short_name
  #string :target
  #end

  def neighborhoods
    sub_areas(target: 'neighborhood')
  end

  def parents
    PoliticalArea.where("lft <= ? and rgt >= ?", self.lft, self.rgt)
  end

  def state
    parents.where(target: 'administrative_area_level_1').where("lft <=? and rgt >=?", self.lft, self.rgt).first
  end

  ## rewrite long_name attribute
  def long_name
    read_attribute(:second_name) ? (read_attribute(:second_name)[0..2] == read_attribute(:long_name)[0..2] ?
                                   read_attribute(:second_name) : read_attribute(:long_name)) : read_attribute(:long_name)
  end

  def rel_area
    arr = []
    tmp = self
    arr << {target: tmp.target, long_name: tmp.long_name}
    while tmp.parent
      tmp = tmp.parent
      arr << {target: tmp.target, long_name: tmp.long_name}
    end
    arr.reverse
  end

  def rel_sub_area_ids(opt={})
    @rel_sub_area_ids ||= if city
                            city.sub_areas(opt).where(self.slice(:long_name, :target)).map{|pc| pc.sub_ids(opt)}.flatten.uniq
                          else
                            []
                          end
  end

  def is_neighborhood?
    self.target == 'neighborhood'
  end

  def city
    @city ||= parents.where(target: 'locality').where("lft <= ? and rgt >= ?", self.lft, self.rgt).first || parents.where('target like ?', 'sublocality%').where("lft <= ? and rgt >= ?", self.lft, self.rgt).first
  end

  def borough
    @borough ||= parents.where('target like ?', 'sublocality%').first || begin
    borough = self
    while borough.target == 'neighborhood'
      borough = borough.parent
    end
    borough
    end
  end

  def full_name
    @full_name ||= begin
                     name = long_name
                     if city && !is_city?
                       name += ", " + city.long_name
                     end
                     if state && !is_state?
                       name += ", " + state.short_name
                     end
                     name
                   end
  end

  def is_city?
    self.target =~ /locality/
  end

  def is_state?
    self.target == 'administrative_area_level_1'
  end

  def set_latlng(opts={})
    if self.ne_lat.blank? || self.lat.blank? || opts[:reset]
      return unless geo.success?
      self.ne_lat, self.ne_lng = geo.suggested_bounds.ne.lat,geo.suggested_bounds.ne.lng
      self.sw_lat, self.sw_lng = geo.suggested_bounds.sw.lat,geo.suggested_bounds.sw.lng
      self.lat, self.lng = geo.lat, geo.lng
      self.save if opts[:autosave]
    end
  end

  def self.set_latlng(opts={})
    unscoped.all.each do |area|
      area.set_latlng(opts)
    end
  end

  def set_permalink opt= {save_flag: false}
    if opt[:save_flag]
      self.update_columns permalink: self.long_name.to_url
    else
      self.permalink = self.long_name.to_url
    end
  end

  def geo
    @geo ||=  do_geocode(full_name)
  end

  def borough_transport_places
    @borough_transport_places ||= if borough
                                    if borough.transport_places.present?
                                      borough.transport_places
                                    else
                                      if PoliticalArea.boston.sub_ids(include_self: true).include?(borough.id)
                                        PoliticalArea.boston.transport_places
                                      else
                                        if city
                                          same_borough = city.sub_areas.where('long_name = ? and target like ? and id != ?',borough.long_name, 'sublocality%', borough.id)
                                          pl = nil
                                          same_borough.each do |br|
                                            if br.transport_places.present?
                                              pl = br.transport_places
                                              break
                                            end
                                          end
                                          pl
                                          if pl.blank?
                                            if city.long_name == 'New York' || self.long_name == 'Newport' || self.long_name == 'Hoboken' || self.long_name == 'Hudson Exchange' || self.long_name == 'Jersey City' || self.long_name == 'Downtown Jersey City' || self.long_name == 'Colgate Center' || self.long_name == 'The Waterfront' || self.long_name == 'Historic Downtown'
                                              pl = TransportPlace.first.political_area.transport_places
                                            end
                                          end
                                          pl
                                        else
                                          TransportPlace.first.political_area.transport_places
                                        end
                                      end
                                    end
                                  else
                                    TransportPlace.first.political_area.transport_places
                                  end
  end

  def hottest_spots
    borough_transport_places.where('place_type != ? or place_type is null', 'College') if borough_transport_places
  end
  def colleges
    borough_transport_places.where('place_type = ?', 'College') if borough_transport_places
  end

  def sub_areas(opt = {})
    areas = PoliticalArea.all
    if opt[:target]
      areas = areas.where('target = ?', opt[:target])
    end
    nearby_area_sql = ""
    if opt[:include_nearby].nil? || opt[:include_nearby]
      if nearby_areas.present?
        nearby_areas.each do |near_area|
          nearby_area_sql += " or (lft >= #{near_area.lft} and lft <= #{near_area.rgt})"
        end
      end
    end
    if opt[:include_self]
      areas = areas.where("(lft >= ? and lft <= ?) #{nearby_area_sql}", self.lft, self.rgt)
    else
      areas = areas.where("(lft > ? and lft < ?) #{nearby_area_sql}", self.lft, self.rgt)
    end
    areas
  end

  def nearby_areas
    if self.long_name == 'Boston'
      @nearby_areas ||= self.parent.children.where('(target = ? and (long_name = ? or long_name = ?))', 'locality', 'Cambridge', 'Somerville')
    elsif self.long_name == 'New York'
      PoliticalArea.where('(long_name=? and id < ?) or long_name = ? or long_name = ? or (long_name=? and id > ?) or (long_name=? and id < ?) or long_name = ? or long_name = ? or (long_name=? and id < ?)', 'Newport', 2000, 'Hoboken', 'Hudson Exchange', 'Jersey City', '800', 'Downtown Jersey City', '1000', 'Colgate Center', 'The Waterfront', 'Historic Downtown', '5000')
    end
  end

  def sub_ids(opt = {})
    @sub_ids ||= sub_areas(opt).map(&:id)
  end

  def all_listings(query={})
    Listing.where(query).where(political_area_id: sub_ids(include_self: true))
  end

  def lines(area_name = nil)
    case (area_name || city.long_name.downcase)
    when 'new york'
      MtaInfoLine.nyc_lines
    when 'philadelphia'
      MtaInfoLine.philadelphia_lines
    else
      MtaInfoLine.where('id < 0')
    end
  end
  def all_sts(area_name = nil)
    case (area_name || city.long_name.downcase)
    when 'new york'
      MtaInfoSt.where(mta_info_line_id: MtaInfoLine.nyc_line_ids)
    when 'philadelphia'
      MtaInfoSt.where(mta_info_line_id: MtaInfoLine.philadelphia_line_ids)
    else
      MtaInfoSt.where('id < 0')
    end
  end

  def rel_area
    arr = []
    tmp = self
    arr << {target: tmp.target, long_name: tmp.long_name}
    while tmp.parent
      tmp = tmp.parent
      if tmp.target =~/sublocality_leve/
        tmp.target = 'sublocality'
      end
      arr << {target: tmp.target, long_name: tmp.long_name}
    end
    arr.reverse
  end

  def real_area
    last_area = nil
    rel_area.each do |opt|
      if last_area
        last_area = last_area.children.where(opt).first || PoliticalArea.create!(opt.merge(parent_id: last_area.id))
      else
        last_area = PoliticalArea.where(opt).first
      end
    end
    last_area
  end

  class << self
    Settings.cities.each do |city, opt|
      define_method city do
        instance_variable_get("@#{city}") || instance_variable_set("@#{city}", unscoped.where(opt).first)
      end
    end

    def find_city(city)
      city.strip!
      city = 'New York' if city =~ /new-york/i
      PoliticalArea.where(target: 'locality', long_name: city).first
    end

    def retrieve_from_address_compontents(compontents=[])
      last_political_area = nil
      return nil if compontents.blank?
      compontents.each do |compontent|
        political = compontent['types'].delete('political')
        if political.present?
          target = compontent['types'].last
          params = {long_name: compontent['long_name'], target: target}
          if last_political_area.present?
            params['parent_id'] = last_political_area.id
          end
          political_area = where(params).first || create!(params.merge(short_name: compontent['short_name']))
          last_political_area = political_area
        end
      end
      last_political_area
    end
    def retrieve_from_neighborhood(neighborhood, parent = nil)
      p = find_neighborhood(neighborhood, parent)
      return p if p.present?
      json = AddressComponent.decorator(components: "neighborhood:#{neighborhood}", address: neighborhood)
      if json
        retrieve_from_address_compontents(json['address_components'])
      end
    end
    def find_neighborhood(neighborhood, parent = nil)
      if parent
        p = where('lft > ? and lft < ?', parent.lft, parent.rgt).where('long_name = ? and target=?', neighborhood, 'neighborhood').first
      else
        p = where('long_name = ? and target=?', neighborhood, 'neighborhood').first
      end
      p
    end

    def fix_political_areas opt = {}
      fix_political_areas_for_sublocality opt
      fix_political_areas_for_dup opt
    end
    def fix_political_areas_for_sublocality(opt={})
      ## fix sublocality
      PoliticalArea.where(target: 'locality').where(opt).pluck(:id).each do |c_id|
        city = PoliticalArea.find_by_id c_id
        if city
          city.children.where(target: 'sublocality').pluck(:id).each do |s_id|
            sc_city = PoliticalArea.find_by_id s_id
            if sc_city
              sc_city.sub_areas.where(target: 'sublocality').pluck(:id).each do |sb_id|
                sb = PoliticalArea.find_by_id sb_id
                next unless sb
                sb1 = sb.sub_areas(include_self: true).where(sb.slice(:target, :long_name)).order(id: :desc).first || sb
                real_sb = city.children.where(sb1.slice(:target, :long_name)).first
                if real_sb
                  sb.sub_areas(include_self: true).each do |sb_ng|
                    real_sb.reload
                    sc_city.reload
                    rl_ng = sc_city.sub_areas(include_self: true).where(sb_ng.slice(:target, :long_name)).where.not(id: sb_ng).first ||
                      real_sb.sub_areas(include_self: true).where(target: sb_ng.target, long_name: sb_ng.long_name).first ||
                      real_sb.children.create(sb_ng.slice(:target, :long_name, :short_name, :second_name))
                    ll_ids = Listing.enables.where(political_area: sb_ng).pluck(:id)
                    Listing.where(id: ll_ids).update_all political_area_id: rl_ng.id
                    if rl_ng.borough != sb_ng.borough
                      Listing.where(id: ll_ids).each{|l| l.cancel_cal}
                      Listing.where(id: ll_ids).enables.each{|s| s.save}
                    end
                    sb_ng.reviews.update_all political_area_id: rl_ng.id
                    sb_ng.venues.update_all political_area_id: rl_ng.id
                  end
                  sb.sub_areas(include_self: true).update_all enabled: false
                  # sb.destroy
                end
              end
            end
          end
        end
      end
    end

    def fix_political_areas_for_dup opt = {}
      ## fix neighborhood
      PoliticalArea.where(target: 'locality').where(opt).order(id: :asc).pluck(:id).each do |c_id|
        city = PoliticalArea.find_by_id c_id
        next unless city
        city.neighborhoods.order(id: :asc).pluck(:id).each do |ng_id|
          ng = PoliticalArea.find_by_id ng_id
          next unless ng
          city.reload
          others = city.sub_areas.where(target: ng.target, long_name: ng.read_attribute(:long_name)).where.not(id: ng.id)
          others.each do |other|
            other.children.each{|child|
              child.reload
              child.parent = ng
              child.save
            }
          end
          Listing.where(political_area: others).update_all political_area_id: ng.id
          Review.where(political_area: others).update_all political_area_id: ng.id
          Venue.where(political_area: others).update_all political_area_id: ng.id
          others.update_all enabled: false
        end
      end
    end
    #all.each do |area|
    #if exists?(area)
    ## area.destroy if area.all_listings.blank?
    #end
    #end
    #ny_state = where(long_name: 'New York', target: 'administrative_area_level_1').first
    #ny_state.children.where(target: 'sublocality').each do |sublocal|
    #if nyc.sub_areas.where(target: sublocal.target, long_name: sublocal.long_name).present?
    #sublocal.all_listings.enables.each do |listing|
    #area = PoliticalArea.nyc.sub_areas.where(target: listing.political_area.target, long_name: listing.political_area.long_name).first
    #if area
    #listing.political_area = area
    #listing.save
    #end
    #end
    #end
    #end

    def all_city_sub_area_ids
      @all_city_sub_area_ids ||= all_cities.map{|s| s.sub_ids(include_self: true)}.flatten.uniq
    end

    def all_cities
      @all_cities ||= Settings.cities.keys.map{|s| PoliticalArea.send s}
    end

    def default_area
      @default_area ||= where(Settings.default_area).first_or_initialize
    end
    def neighborhoods_by(city)
      @@neighborhoods[city.short_name] ||= begin
                                             city.sub_areas.order(id: :asc).map do |area|
                                               [area.long_name, area.long_name, {parent: area.borough.long_name}]
                                             end.uniq{|s| s[0]}
                                           end
    end

    def pcvst_ids
      nyc.sub_areas.where('long_name = ? or long_name = ?', 'Peter Cooper Village', 'Stuyvesant Town').pluck :id
    end

    def fix_nil_political_areas
      hash = {}
      [Listing, Review, Venue].each do |kclass|
        kclass.where.not(political_area: PoliticalArea.all).distinct(:political_area_id).pluck(:political_area_id).each do |p_id|
          kclass.where(political_area_id: p_id).each do |l|
            if hash[p_id]
              l.update_attributes political_area_id: hash[p_id]
            else
              l.political_area_id = nil
              l.reimprove if l.respond_to?('reimprove')
              l.save
              if l.political_area_id
                hash[p_id] = l.political_area_id
              else
                break
              end
            end
          end
        end
      end
    end
  end
end
