class DeleteFileWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  def perform(url)
    prefix = File.dirname(URI(url).path)[1..-1]
    bucket = URI(url).hostname.split('.').first 
    files  = ListingImage.fog_s3.directories.get(bucket, prefix: prefix).files.map{|file| file.key}
    if Rails.env.production?
      ListingImage.fog_s3.delete_multiple_objects(bucket, files)
    end
  end
end
