class FloorplanUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  #include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage (Rails.env.development? ? :file : :fog)

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end
  def cover
    pdf = MiniMagick::Image.open(self.file.path)
    pdf.pages.first
  end

  # Create different versions of your uploaded files:
  version :thumb do
    process :cover
    process :resize_to_fill => [300, 267]
    process :convert => 'jpg'

    def full_filename (for_file = model.image.file)
      super.chomp(File.extname(super)) + '.jpg'
    end
  end

  #version :thumb, :if => :image? do
  #  process :resize_to_fill => [242, 200]
  #  process :convert => 'jpg'

  #end
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w(jpg jpeg png pdf)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
  protected
    def pdf?(new_file)
      new_file.content_type == "application/pdf"
    end

    def image?(new_file)
      new_file.content_type.start_with? 'image'
    end

end
