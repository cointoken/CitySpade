class SpadePassImage < ActiveRecord::Base
  belongs_to :spade_pass
  mount_uploader :image, SpadePassImageUploader
end
