class ReviewPlace < ActiveRecord::Base
  belongs_to :review
  scope :groceries, -> { where(place_type: 'grocery') }
  scope :laundries, -> { where(place_type: 'laundry') }
end
