module FogS3
  def tmp_file(size = nil)
    File.join(tmp_image_dir, size || 'origin')
  end

  def tmp_image_dir
    @tmp_image_dir #||= begin
    #dir = File.join(Rails.root, 'tmp', 'image')
    #FileUtils.mkdir_p(dir) unless File.exist? dir
    #dir
    #end
  end
  def create_tmp_image_dir
    @tmp_image_dir = File.join(Rails.root, 'tmp', 'image', "#{self.class}#{self.id}-#{Time.now.to_f}-#{rand(10)}")
    FileUtils.mkdir_p(@tmp_image_dir) unless File.exist?(@tmp_image_dir)
  end

  def check_and_upload_img_to_s3
    if self.origin_url.present? && need_upload?#(self.s3_url.blank? || self.sizes != default_sizes)
      upload_img_to_s3
    elsif self.changed.include?('origin_url')
      self.sizes = []
      self.s3_url = nil
      upload_img_to_s3
    end
  end

  def need_upload?
    if self.s3_url.present? && self.sizes.present?
      unless self.default_sizes.any?{|s| !self.sizes.include?(s)}
        return false
      end
    end
    true
  end

  def s3_directoriy
    @directories ||= ListingImage.fog_s3.directories.create(key: Settings.aws.s3_bucket, public: true)
  end

  def default_sizes
    Settings.image_sizes.send(self.class.to_s)
  end

  def upload_img_to_s3
    create_tmp_image_dir
    begin
      res = response_from_origin_url
      return unless res.code == '200'
      content_type = res.content_type
      return unless content_type.include?('image') or !content_type.include?('text')
      File.open(tmp_file, 'wb') do |img|
        img.write res.body
      end
      origin_file = tmp_file
      ## check if file is valid image
      image = MiniMagick::Image.new(origin_file)
      return unless image.valid?

      if self.sizes.blank?
        file = s3_directoriy.files.create(:key=> s3_image_path, :body => res.body , :public => true, :content_type => content_type )
        self.sizes = ['origin']
        self.s3_url = file.public_url.sub(/origin$/, '')
      end
      default_sizes.each do |size|
        next if self.sizes.include?(size) || !size
        image = MiniMagick::Image.open(origin_file)
        size_file = tmp_file(size)
        image.decorator_resize(size)
        image.write size_file
        s3_directoriy.files.create(:key => s3_image_path(size), :body => File.read(size_file), :public => true, :content_type => content_type)
        self.sizes << size
      end
    rescue =>e
      Rails.logger.info e
      Rails.logger.info e.backtrace.inspect
    end
    del_tmp_files
  end

  def del_tmp_files
    Dir[File.join(@tmp_image_dir, '*')].each do |tmp|
      FileUtils.rm tmp if File.exist? tmp
    end
    FileUtils.rmdir @tmp_image_dir if File.exist? @tmp_image_dir
  end

  def url(size = nil)
    return nil if sizes.blank? || self.s3_url.blank?
    if size
      if size == '480X400' && sizes.include?('600X420')
        return (self.s3_url.to_s + '600X420')
      elsif sizes.include?(size.sub('x', 'X'))
        return (self.s3_url.to_s + size.sub('x', 'X'))
      end
    end
    (self.s3_url + 'origin') if self.s3_url.present?
  end

  def response_from_origin_url
    if self.s3_url.present? && self.sizes.present?
      url = self.url('origin')
    else
      url = self.origin_url
    end
    res = FogS3.spider.get(URI::escape(url))
    # fix elliman image disable
    if res.code != '200' && url =~ /elliman\.com/
      res = FogS3.spider.get(url.gsub(/\+.+/, '+440++1'))
    end
    res
  end

  def FogS3.spider
    @spider ||= Spider::Base.new
  end

  def s3_image_path(size = 'origin')
    if self.s3_url.blank?
      File.join(s3_image_dir, size)
    else
      File.join(URI(self.s3_url).path.sub(/^\//,''), size)
    end
  end

  def s3_image_dir
    if self.class == Agent
      File.join('agents',self.id.to_s, Digest::MD5.hexdigest(self.origin_url))
    elsif self.class == ListingImage
      File.join('listings',self.listing_id.to_s, Digest::MD5.hexdigest(self.origin_url))
    end
  end

  #def delete_file_from_s3(bucket = Settings.aws.s3_bucket)
  # if self.s3_url && self.sizes
  #      self.sizes.each do |size|
  #        begin
  #          key = self.url(size)
  #          file = $fog_s3.files.new key: key
  #          file.destroy
  #        rescue => e
  #          Rails.logger.info e.backtrace.inspect
  #        end
  #      end
  #    end
  #end

  def self.included(base)
    base.before_save :check_and_upload_img_to_s3
    # base.after_destroy :delete_file_from_s3
    def base.reupload_img_to_s3
      all.each do |img|
        img.upload_img_to_s3
        img.save
      end
    end
  end
end
MiniMagick::Image.send :include, ImageHelper
