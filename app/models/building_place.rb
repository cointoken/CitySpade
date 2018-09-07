class BuildingPlace < ActiveRecord::Base
  belongs_to :building
  has_many :building_mta_lines

  scope :find_target, ->(t) { where("target like '%#{t}%'") }
  scope :st_places, -> { where("target like '%subway%' or target like '%bus%'") }

end
