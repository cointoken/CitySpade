class RoomDetail < ActiveRecord::Base
  belongs_to :room
  serialize :amenities, Array
  serialize :pets_allowed, Array
  validates :description, length: {minimum: 140}
end
