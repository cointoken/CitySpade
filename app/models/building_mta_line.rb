class BuildingMtaLine < ActiveRecord::Base
  belongs_to :building
  belongs_to :mta_info_line
  belongs_to :building_place
  belongs_to :mta_info_st

  delegate :icon_url, to: :mta_info_line
  delegate :lat, to: :station
  delegate :lng, to: :station
  delegate :name, to: :station

  def station
    building_place || mta_info_st
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

  def line_name
    mta_info_line.name
  end

  def station_name
    station.name
  end


  include BuildingMtaLineHelper

end
