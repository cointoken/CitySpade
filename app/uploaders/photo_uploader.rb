class PhotoUploader < BaseUploader

  #storage :storage
  #if model.default_sizes.present?
    #model.default_sizes.each do |value|
      #version "v_#{value}" do
        #process :custom_decorator_resize => value
      #end
    #end
  #else
    {small: [120, 120], thumb: [280, 200]}.each do |key, value|
      version key do
        process :custom_decorator_resize => value
      end
    end

   # version :custom do
      #process :custom_decorator_resize => :custom
    #end
    ##version "#{key}_origin" do
    ##process :resize_to_limit => value
    ##end
  #end
end
