class SearchRecord < ActiveRecord::Base
  serialize :beds, Array
  serialize :baths, Array
  scope :enables, -> { where("title is not null and title != '' and featured = true") }

  belongs_to :account
end
