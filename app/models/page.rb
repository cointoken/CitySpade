class Page < ActiveRecord::Base
  validates_uniqueness_of :permalink
  # validates_presence_of :name
  has_many :page_views,as: :page, dependent: :destroy

  # change auto path to /pages/:permalink, e.g. /pages/term, /pages/about
  def to_param  # overridden
    permalink
  end

  def self.from_param(param)
    find_by_permalink!(param)
  end

end
