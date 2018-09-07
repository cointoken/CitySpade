module DeleteFilesFromS3
  def bucket
    URI(self.url).hostname.split('.').first if self.url.present?
    # self.url.split("/")[2].split(".")[0]
  end

  def files
    ListingImage.fog_s3.directories.get(bucket,prefix: prefix).files.map{ |file| file.key }
  end

  def prefix
    File.dirname(URI(self.url).path)[1..-1]
  end

  def delete_file_from_s3(file)
    ListingImage.fog_s3.delete_object(bucket,file) if bucket
  end

  def delete_fold_rescrusive_from_s3
    # $fog_s3.delete_multiple_objects(bucket,files) if bucket
    DeleteFileWorker.perform_async(self.url) if self.url.present?
  end

  def self.included(base)
    base.after_destroy :delete_fold_rescrusive_from_s3
  end
end
