class Listing < ActiveRecord::Base

  # place_flag
  # 0 => no get places info
  # +1 => areally get places info
  # +2 => get subway lines
  # +4 => cal transport distance
  # status
  #  -1 => deactived(It belongs to Account)
  #  0 => active or normal
  # ------- this is expired listings below---------
  #  1 => deactivate(It belongs to Spider)
  #  >=2 && < 10 other status
  #    3 => because of neighborhood(PCVST)
  #    4 => cal address error
  #  >= 10 && < 20 deactivate,and delete the listing references
  #  >= 20 && < 30 address or title disable
  #  30 target url disable
  #  34 => price or listing error
  #  ==> only < 20 can access

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

  attr_writer :description, :amenities, :never_has_url, :current_step
  attr_writer :city_name, :state_name, :open_houses, :detail_hash
  attr_accessor :listing_provider_id, :agent_first_name, :agent_last_name, :email
  alias_attribute :neighborhood_name, :raw_neighborhood

  acts_as_mappable

  # kaminari per
  paginates_per 14

  serialize :image_sizes, Array

  belongs_to :political_area
  belongs_to :agent
  belongs_to :broker
  belongs_to :review_building, class_name: 'Venue', foreign_key: :building_venue_id
  belongs_to :account
  has_one :mls_info, dependent: :destroy
  has_one :listing_provider, dependent: :destroy
  has_many :listing_urls, dependent: :destroy
  has_many :listing_images, -> { where('s3_url is not null').order('origin_url DESC').limit(10) }, dependent: :destroy
  has_many :listing_mta_lines,  dependent: :destroy
  has_many :transport_distances, dependent: :destroy
  has_many :transport_places, through: :transport_distances
  has_many :reputations, as: :reputable, dependent: :destroy
  has_many :page_views, as: :page, dependent: :destroy
  has_many :listing_places, -> { order :distance }, dependent: :destroy
  has_many :open_houses, -> { order(open_date: :asc) }, dependent: :destroy
  has_one :listing_detail, dependent: :destroy

  has_many :photos, class_name: Photo::Listing, as: :imageable, dependent: :destroy

  accepts_nested_attributes_for :listing_detail



  #alias_method :images, :listing_images
  alias_method :urls, :listing_urls
  alias_method :places, :listing_places

  # default_scope -> { includes(:score,:listing_urls, :listing_images).references(:score,:listing_images, :listing_urls) }

  # validates_inclusion_of :listing_type, in: Settings.listing_types
  # flag, 0 => sales, 1 => rentals
  validates_inclusion_of :flag, in: [0, 1]
  validates_numericality_of :price, greater_than: 100
  #validates_numericality_of :price, greater_than: 30000, if: ->(listing){ !listing.is_rental? }
  #validates_numericality_of :price, less_than: 40000, if: ->(listing){ listing.is_rental? && (listing.beds.to_i + 1) * 20000 < listing.price.to_i }
  # new york city zipcode
  validates_format_of :zipcode, with: /\A\d{5}\Z/, allow_nil: true
  validates_presence_of :contact_name, if: ->(listing) { listing.broker_name.blank? && listing.broker_id.blank? && listing.account_id.blank? }#, :title
  validates_presence_of :contact_tel, if: ->(listing) { !listing.is_mls? && listing.listing_provider_id.blank? && !listing.listing_provider && listing.account_id.blank? }
  validates_uniqueness_of :origin_url,
                conditions: -> { where.not(contact_name: ['AvalonBay Communities','Equity Residential', 'Bozzuto Management']) },
                if: ->(listing) { !listing.never_has_url? && listing.listing_provider_id.blank? && !listing.listing_provider }
  validates_presence_of :origin_url, if: ->(listing) { !listing.never_has_url? && listing.listing_provider_id.blank? && !listing.listing_provider }
  validates_with PriceValidator
  validates_with FormattedAddressValidator

  include DontAutoSaveSerialized
  include CheckAddress
  include ListingHelper
  include ListingBrokerHelper
  include ListingFeaturedHelper
  extend ListingSearch

  delegate :avatar_url, to: :agent, prefix: true, allow_nil: true
  delegate :maintenance, to: :listing_detail, allow_nil: true

  def current_step
    @current_step
  end

  def never_has_url
    if new_record?
      !!@never_has_url
    else
      self.origin_url.blank?
    end
  end

  def listing_subway_lines
    @subway_lines ||=begin
                       lines = listing_mta_lines.where(target: 'subway').where('listing_mta_lines.distance < ?', 1200).to_a.uniq{|s| s.mta_info_line_id}
                       if lines.blank?
                         listing_mta_lines.where(target: 'subway').to_a.uniq{|s| s.mta_info_line_id}
                       else
                         lines
                       end
                     end
  end

  def listing_bus_lines
    @bus_lines ||= listing_mta_lines.where(target: 'bus').uniq{|s| s.mta_info_line_id}
  end

  alias_method :never_has_url?, :never_has_url
  alias_method :subway_lines, :listing_subway_lines
  alias_method :bus_lines, :listing_bus_lines
  alias_attribute :url, :origin_url

  def beds
    (read_attribute('beds')||0).ceil
  end

  def image_url(size = 'origin')
    if self.account_id && self.listing_image_id
      img = Photo::Listing.find self.listing_image_id
      if img
        img.image.try("v_#{size}").try(:url) || img.image.url
      end
    else
      if image_base_url && image_sizes.present?
        if image_sizes.include?(size)
          image_base_url + size
        else
          if size == '360X240' && image_sizes.include?('300X180')
            return image_url('300X180')
          end
          image_base_url + 'origin'
        end
        # else
        # ActionController::Base.helpers.asset_path('')
        #images.last.try(:url, size)
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
  def neighborhood_name(target = :long)
    read_attribute(:raw_neighborhood) || begin
    long_name = political_area.try(:long_name)
    if long_name && target != :long
      long_name.split('/').first.strip
    else
      long_name
    end
    end
  end

  def expired?
    self.status == 1
  end

  def has_floorplans?
    self.listing_images.floorplans.count != 0
  end

  def area_zipcode
    "#{neighborhood_name}, #{state.try(:short_name)}, #{zipcode}" if neighborhood_name && zipcode
  end

  def to_param
    if formatted_address.present?
      [id, display_title.remove('#'), formatted_address.split(',')[1..-2], "for-#{flag_name}"].join(' ').to_url
    else
      [id, address_title.remove('#'), neighborhood_name, state.try(:short_name), zipcode, "for-#{flag_name}"].join(' ').to_url
    end
  end

  def buil_param
      [id]
  end

  #def full_title
  #if formatted_address.present?
  #["for-#{flag_name} in #{title}", formatted_address.split(',')[1..-2]].join(', ')
  #else
  #["for-#{flag_name} in #{title}", neighborhood_name, state.try(:short_name), zipcode].join(', ')
  #end
  #end

  def flag_name
    is_rental? ? 'rent' : 'sale'
  end

  def permalink
    "/listings/#{to_param}"
  end

  def build_peramlink
    "/buildings/#{buil_param}"
  end

  def trans_by_place(place)
    transport_distances.where(transport_place: place).
      where('(mode = :mode and duration <= :dur) or (mode != :mode)', mode: 'walking', dur: 20 * 60).order('mode desc').first
  end

  def subway_lines_order_by_color
    # order by color  where the listing city is new york
    if self.city.long_name == 'New York'
      self.subway_lines.sort{|x, y|
        x_l = x.icon_url.split('.')[-2].split('_').last
        y_l = y.icon_url.split('.')[-2].split('_').last
        "#{x.distance_text.split(' ').reverse.join}#{NYC_LINECOLORS[x_l]}" <=> "#{y.distance_text.split(' ').reverse.join}#{NYC_LINECOLORS[y_l]}"
      }
    else
      self.subway_lines
    end
    # 这样处理觉得比较繁杂
    #self.subway_lines.each do |line|
    #origin_url = line.icon_url
    #l = origin_url.split('/').last.split('.').first.split("_").last
    #[:red, :green, :blue, :orange, :brown,
    #:yellow, :gray, :dark].each do |color|
    #colors[color] = [] if colors[color].nil?
    #colors[color] << line if Colors[color].include?(l)
    #end
    #end

    #colors.values.flatten.sort do |x, y|
    #x.distance_text <=> y.distance_text
    #end
  end

  def relative_listings(opt={kms: 2})
    # 查找附近1公里内的相关信息
    similar_listings = Listing.enables.where(flag: self.flag).where(beds: self.beds, baths: self.baths, is_full_address: true)
      .where('listings.id != ? and listing_image_id is not null', self.id)
    similar_listings = similar_listings.order("FORMAT((abs(listings.lat - #{self.lat}) + abs(listings.lng - #{self.lng})) / 3, 3)").order('score_price + score_transport desc')
    # similar_listings = similar_listings.within(3, units: :kms, origin)
    similar_listings.where(political_area_id: self.political_area.borough.sub_ids(include_self: true)).limit 15
    #if rel_listings.count < 12
    #similar_listings.limit 12
    #else
    #rel_listings
    #end
  end

  def relative_reviews(opt={})
    return [] if self.city.blank?
    rel_reviews = []
    review_city = City.find_by_name(self.city.short_name) || City.find_by_name('New York')
    apt_review = Review.where(review_type: 0, complete: true).within(
      0.3 , units: :kms, origin: [self.lat, self.lng]
    ).order("full_address = \"#{self.formatted_address}\" desc").order_by_rating(review_city)
    apt_review = apt_review.first
    rel_reviews << apt_review if apt_review
    str_review = Review.where(review_type: 1, complete: true).within(
      1, units: :kms, origin: [self.lat, self.lng]
    ).order("full_address = \"#{self.formatted_address}\" desc").order_by_rating(review_city)
    if apt_review
      str_review = str_review.where('id != ? and venue_id != ?', apt_review.id, apt_review.venue_id)
    end
    str_review = str_review.first
    rel_reviews << str_review if str_review
    neigh_review = Review.where(complete: true).where(review_type: 0).within(
      1, units: :kms, origin: [self.lat, self.lng]
    )
    neigh_review = neigh_review.order_by_rating(review_city)
    if rel_reviews.present?
      neigh_review = neigh_review.where("id not in (#{rel_reviews.map(&:id).join(',')})").where("venue_id not in (#{rel_reviews.map(&:venue_id).join(',')})")
    end
    neigh_review = neigh_review.limit(3 - rel_reviews.size).group(:venue_id)
    rel_reviews << neigh_review.to_a if neigh_review.present?
    rel_reviews.flatten.sort{|rv1, rv2| (rv1.lat - self.lat) ** 2 + (rv1.lng - self.lng) ** 2 <=>
                             (rv2.lat - self.lat) ** 2 + (rv2.lng - self.lng) ** 2
    }
  end

  def self.lightning(*columns)
    has_image_size = columns.include?(:image_sizes)
    connection.select_all(select(*columns).arel).each{|attr|
      if has_image_size && attr['image_sizes']
        attr['image_sizes'] = YAML.load attr['image_sizes']
      end
      if attr['price']
        tmp = attr['price'] / 1000.0
        if attr['flag'] == 1
          attr['price_k'] = "$#{tmp.round(2)}k"
        else
          attr['price_k'] = "$#{tmp.to_i}K"
        end
      end
      attr
    }

    # attrs[attr] = Listing.type_cast_attribute(attr, attrs)
  end

  def building_reviews
    Review.buildings.distinct_venues.where(complete: true).order("POWER((reviews.lat - #{self.lat}), 2) + POWER((reviews.lng - #{self.lng}), 2)")
  end

  def neighborhood_reviews
    Review.neighborhoods.distinct_venues.where(complete: true).where("cross_street <> '' and address <> '' and building_name <> ''")
      .where("full_address like ?", "%&%").order("power(reviews.lat - #{self.lat}, 2) + power(reviews.lng - #{self.lng}, 2) asc")
      .order("reviews.political_area_id = #{self.political_area_id} desc")
  end
  #pluck(*columns).map do |val|
  #obj = {}
  #columns.each_with_index do |col, index|
  #obj[col] = val[index]
  #end
  #obj
  #end

  # def self.remove_zero_beds_with_high_price
  #self.where("origin_url like ?", "%idealpropertiesgroup%").each do |ll|
  #ll.delete if ll.beds.to_f <= 0 and ll.price.to_i >= 3800
  #end
  #end
  #def self.fix_all_zipcode
  #self.all.each do |ll|
  #ll.update_column(:zipcode, nil) if ll.zipcode.present? and ll.zipcode.match(/\A\d{5}\Z/).blank?
  #end
  #end
  def self.fix_realtymx_description
    res = RestClient.get("http://www.realtymx.com/demo/admin/tools/cityspade.xml")
    xmls = Nokogiri::XML(res).xpath("//Listing")
    xmls = xmls.map{|xml| xml.to_hashie}
    Listing.realtymx.each do |li|
      if li.description.match(/\$1/)
        index = nil
        xmls.each_with_index do |xml, i|
          if xml["listing_details"]["listing_url"] == li.origin_url
            index = i
            break
          end
        end
        if index
          desc = xmls[index]["basic_details"]["description"].gsub(/[\.\!] ([A-Z\d])/) {|s| "#{$1}\r\n #{$2}" }.
            gsub(/\.(Contact)/i) {|s| ".\r\n #{$1}"}
          li.listing_detail.update_column(:description, desc)
        end
      end
    end
  end

  #cityspade exclusives
  def cityspade_exclusive
    if self.contact_name == "CitySpade"
      return true
    else
      return false
    end
  end

  def self.fix_livecharlesgate_unit
    self.livecharlesgate.where("unit like ?", "%\n\t%").each do |li|
      unit = li.unit.split("\n\t").first.strip
      li.update_column(:unit, unit)
    end
  end

  ## TODO: fix Spider::Feeds::Benjaminrg
  def self.complete_benjaminrg_address
    self.benjaminrg.update_all(is_full_address: true)
  end

  ## TODO: fix Chicago unit
  def self.fix_chicago_unit
    self.where("origin_url like ?", "%diversesolutions%").each do |chi|
      if chi.title.split(" ").first.gsub(/\D/, "") == chi.unit.gsub(/\D/, "")
        chi.update_column(:unit, nil)
      end
    end
  end

  def self.to_csv
    url = "https://www.cityspade.com/listings/"
    CSV.generate do |csv|
      csv << ["ID", "Broker Name", "Title", "Url", "Page View"]
      all.each do |listing|
        final_url = url+listing.id.to_s
        csv << [listing.id, listing.broker.try(:name), listing.title, final_url, listing.page_views.sum(:num)]
      end
    end
  end
end
