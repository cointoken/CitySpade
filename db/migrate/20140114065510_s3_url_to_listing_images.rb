class S3UrlToListingImages < ActiveRecord::Migration
  def change
    add_column :listing_images, :s3_url, :string
    remove_column :listing_images, :tag
    remove_column :listing_images, :size
  end
end
