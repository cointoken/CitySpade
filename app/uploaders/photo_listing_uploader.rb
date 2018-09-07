class PhotoListingUploader < BaseUploader
  #storage :file
  ListingImage.default_sizes.each do |value|
    version "v_#{value}" do
      process :custom_decorator_resize => value
    end
  end
  alias_method :small, "v_#{ListingImage.default_sizes[0]}"
end
