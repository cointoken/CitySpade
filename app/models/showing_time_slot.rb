class ShowingTimeSlot < ActiveRecord::Base
  has_many :book_showings, foreign_key: :slot_id
end
