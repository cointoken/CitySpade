# encoding: utf-8

class DocumentUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  #after :remove, :clear_uploader
  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage (Rails.env.development? ? :file : :fog)

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
  #  #"uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    "uploads/#{model.class.to_s.underscore}/#{model.id}"
  end

  def fog_public
    false
  end

  def fog_authenticated_url_expiration
    90000
  end


  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w(pdf jpg jpeg png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    if original_filename.present?
      var = :"@#{mounted_as}_secure_token"
      if model && model.read_attribute(mounted_as).present?
        model.instance_variable_get(var)
      else
        filename = "#{secure_token(4)}.#{file.extension}"
        model.instance_variable_set(var, filename)
      #store_path(filename)
      end
    end
  end

  #def clear_uploader
  #  @file = @filename = @original_filename = @cache_id = @version = @storage = nil
  #  model.send(:write_attribute, mounted_as, nil)
  #end

  #def store_path(for_file=filename)
  #  File.join([store_dir, full_filename(for_file)].compact)
  #end

  protected

  def secure_token(length=16)
    #var = :"@#{mounted_as}_secure_token"
    #model.instance_variable_get(var) or model.instance_variable_set(var, 
    get_filename+SecureRandom.hex(length/2)

    #file_name = client_name+SecureRandom.hex(length/2)
  end

  def get_filename
    client =  ClientApply.find(model.client_id)
    client.first_name + client.last_name + "_#{self.model.doc_type}_"
  end

end
