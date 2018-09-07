class ListingPlace < ActiveRecord::Base
  belongs_to :listing
  has_many :listing_mta_lines

  scope :find_target, ->(t) { where("target like '%#{t}%'") }
  scope :st_places, -> { where("target like '%subway%' or target like '%bus%'") }

  include PlaceHelper
end
