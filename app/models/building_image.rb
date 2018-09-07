class BuildingImage < ActiveRecord::Base
  belongs_to :building
  mount_uploader :image, BuildingImageUploader
end

