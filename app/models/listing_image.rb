class ListingImage < ActiveRecord::Base
  belongs_to :listing
  serialize :sizes, Array
  # include DontAutoSaveSerialized

  include FogS3
  include ListingImageHelper
  include DeleteFilesFromS3
  #  before_save :uploader_file_to_s3
  #
  after_save :set_default_image_for_listing
  after_destroy :destroy_default_from_listing_image

  def self.fog_s3
    @@fog_s3 ||= Fog::Storage.new(
      :provider => 'AWS',
      :aws_access_key_id => Settings.aws.access_key_id,
      :aws_secret_access_key => Settings.aws.secret_access_key
    )
  end

  def set_default_image_for_listing
    if self.listing && self.listing.listing_image_id.blank?  && self.s3_url.present?
      self.listing.update_columns listing_image_id: self.id, image_base_url: self.s3_url, image_sizes: self.sizes
    end
  end
  def destroy_default_from_listing_image
    if self.listing && self.listing.listing_image_id == self.id
      listing_image_id = self.listing.images.first.try(:id) || nil
      image_base_url   = self.listing.images.first.try(:s3_url) || nil
      image_sizes      = self.listing.images.first.try(:sizes) || nil
      self.listing.update_columns listing_image_id: listing_image_id, image_base_url: image_base_url, image_sizes: image_sizes
    end
  end

  def self.reupload_if(opt={})
    where(opt).pluck(:id).each do |img|
      img = LisitngImage.find_by_id img
      if img
        if img.listing && img.listing.is_enable?
          img.sizes = []
          img.save
        else
          img.destroy
        end
      end
    end
    resize_images_unless_default_sizes
  end

  def self.save_from_mls(images, listing)
    images.each do |img|
      where(origin_url: img[:origin_url], listing_id: listing.id).first_or_create
    end
  end

  def self.fix_images_size opts={}
    default_opts = {max_id: 180000, min_id: 0, time_limit: 5000, begin_yday: 1}.merge opts
    # imgs = #ListingImage.where(listing_id: Listing.enables.map(&:id)).order(id: :desc)
    default_opts[:max_id] = $redis.get("cityspade:listing_images:update_id").to_i if $redis.get("cityspade:listing_images:update_id").present?
    Listing.enables.where("id <= ?", default_opts[:max_id] || Listing.maximum(:id))
      .order(id: :desc).pluck(:id).each do |l_id|
      l = Listing.find l_id
      if l.is_enable?
        l.images.each do |img|
          if img.s3_url.present? && img.sizes.present? && !img.sizes.include?("600X420")
            # img.sizes.delete('480X400')
            img.save
          end
        end
      end
      $redis.set("cityspade:listing_images:update_id", l.id)
    end
  end

  def self.resize_images_unless_default_sizes opt={}
    imgs = ListingImage.all
    if opt.blank?
      imgs = imgs.where(listing: Listing.enables)
      imgs = imgs.where("sizes not like ? or sizes not like ? or sizes not like ?", "%360X240%", "%60X60%", "%480X400%")
    elsif opt == 'moderngroup'
      imgs = imgs.where(listing: Listing.moderngroup).where('updated_at < ?', '2015-01-29')
    end
    imgs.order(id: :desc).limit(5000).pluck(:id).each do |img_id|
      img = ListingImage.find img_id
      if img && img.listing && img.listing.is_enable?
        img.sizes ||= []
        img.sizes.delete_if{|s| s != 'origin'}
        img.save
      else
        img.destroy
      end
    end
  end

  def self.reupload_imgs_for_mns
    ListingImage.where("s3_url is NULL").where("origin_url like ?", "%mns%").each do |img|
      img.save
    end
  end

  def self.default_sizes
    new.default_sizes
  end

  def video_id
    self.s3_url.split('/').last
  end

end
