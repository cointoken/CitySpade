class Listing < ActiveRecord::Base
  has_many :listing_urls
  has_many :listing_images
  has_one :score
  alias_method :urls, :listing_urls
  alias_method :images, :listing_images
end
class Score < ActiveRecord::Base 
end
class AddUrlImageScoreToListings < ActiveRecord::Migration
  def change
    add_column :listings, :listing_url_id, :integer
    add_column :listings, :origin_url, :string
    add_column :listings, :listing_image_id, :integer
    add_column :listings, :image_base_url, :string
    add_column :listings, :image_sizes, :string
    add_column :listings, :score_transport, :float
    add_column :listings, :score_price, :float


    Listing.all.each do |listing|
      if listing.urls.first
        listing.listing_url_id = listing.urls.first.id
        listing.origin_url     = listing.urls.first.url
      end
      if listing.listing_images.first
        listing.listing_image_id = listing.listing_images.first.id
        listing.image_base_url   = listing.listing_images.first.s3_url
        listing.image_sizes      = listing.listing_images.first.sizes
      end
      if listing.score
        listing.score_transport = listing.score.transport
        listing.score_price = listing.score.price
      end
      listing.save
    end
    drop_table :scores
  end
end
