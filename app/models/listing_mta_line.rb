class ListingMtaLine < ActiveRecord::Base
  belongs_to :listing
  belongs_to :mta_info_line
  ## delete the line after some time, the listing_places table never use
  belongs_to :listing_place
  belongs_to :mta_info_st
  
#  default_scope -> { 
    #includes(:mta_info_line).references(:mta_info_line)
    #.order(:distance)}#.group(:mta_info_line_id) }

  delegate :icon_url, to: :mta_info_line
  delegate :lat, to: :station# :listing_place
  delegate :lng, to: :station# :listing_place
  delegate :name, to: :station# :listing_place
  
  def station
    listing_place || mta_info_st
  end

  def title
    "#{name} / #{mta_info_line.name}"
  end

  def distance_text
    tmp = read_attribute(:distance_text)
    if tmp =~ /mi$/
      tmp + "le"
    else
      tmp
    end
  end

  include ListingMtaLineHelper

  def line_name
    mta_info_line.name
  end
  def station_name
    station.name
  end
end
