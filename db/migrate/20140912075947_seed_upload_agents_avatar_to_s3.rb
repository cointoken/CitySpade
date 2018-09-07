class SeedUploadAgentsAvatarToS3 < ActiveRecord::Migration
  def change
    Agent.all.each do |agent|
      agent.check_and_upload_img_to_s3
      agent.save
    end
  end
end
