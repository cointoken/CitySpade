class Photo < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
  mount_uploader :image, PhotoUploader
  include DeleteFilesFromS3

  alias_method :name, :image_identifier
  delegate :size, to: :image

  default_scope ->{ order(is_top: :desc) }

  def to_json_image
    {
      "name" => self.image_identifier,
      "size" => image.size,
      "url" => image.url,
      "thumbnail_url" => image.small.url,
      "delete_url" => "/photos/#{self.id}",
      "picture_id" => self.id,
      "delete_type" => "DELETE"
    }
  end

  def size_name
    k = (size / 1024.0).round(2)
    if k > 0
      m = (k / 1024.0).round(2)
      if m > 1
        "#{m}MB"
      else
        "#{k}KB"
      end
    else
      "1KB"
    end
  end

  def to_jq_upload
    {
      files:[
        {
          "name" => self.image_identifier,
          "size" => image.size,
          "url" => image.url,
          "thumbnail_url" => image.small.url,
          "delete_url" => "/photos/#{self.id}",
          "picture_id" => self.id,
          "delete_type" => "DELETE"
        }
      ]
    }
  end
  def url(size = nil)
    if size
      size.gsub!('x', 'X')
      size = "v_#{size}"
      if image.try(size)
        image.send(size).url
      else
        image.url
      end
    else
      image.url
    end
  end

  def thumb
    image.try(:thumb).try(:url)
  end

  def default_sizes
    imageable_type.constantize.try(:default_sizes) if imageable_type
  end
  def video_id
    self.video_url.split('/').last
  end
end

class Photo::Listing < Photo
  self.table_name = "photos"
  mount_uploader :image, PhotoListingUploader
  def sizes
    ListingImage.default_sizes
  end
end

class Photo::Agent < Photo
  self.table_name = "photos"
  mount_uploader :image, AvatarUploader
  def sizes
    Agent.default_sizes
  end
end
