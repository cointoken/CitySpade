class ListingDetail < ActiveRecord::Base
  belongs_to :listing
  serialize :amenities
end
