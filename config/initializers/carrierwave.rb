CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => Settings.aws.access_key_id,       # required
    :aws_secret_access_key  => Settings.aws.secret_access_key    # required
  }
  config.fog_directory  = Settings.aws.s3_bucket # required
  # see https://github.com/jnicklas/carrierwave#using-amazon-s3
  # for more optional configuration
end

if Rails.env.test?
  CarrierWave.configure do |config|
    config.enable_processing = false
  end
end
