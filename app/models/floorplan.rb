class Floorplan < ActiveRecord::Base
  belongs_to :building
  mount_uploader :image, FloorplanUploader

  validates_presence_of :image, :beds, :baths, :price

  def apt_type(beds)
    if beds == 0
      "Studio"
    elsif beds == 1
      "One Bedroom"
    elsif beds == 2
      "Two Bedroom"
    elsif beds == 3
      "Three Bedroom"
    end
  end
end

