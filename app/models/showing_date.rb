class ShowingDate < ActiveRecord::Base
  has_many :book_showings, foreign_key: :date_id
end
