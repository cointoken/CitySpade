class AvatarUploader < BaseUploader
  version :small do
    process :resize_to_limit => [40, 40]
  end

  version 'v_60X75' do
    process :resize_to_limit => [60, 75]
  end

  version :medium do
    process :resize_to_limit => [140, 280]
  end
end
