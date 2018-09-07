class RemoveUrlToListingImages < ActiveRecord::Migration
  def change
#    if ActiveRecord::Base.connection_config[:database] =~ /sqlite/
      #execute %q{
        #ALTER TABLE "main"."listing_images" RENAME TO "oXHFcGcd04oXHFcGcd04_listing_images";}
      #execute %q{
        #CREATE TABLE "main"."listing_images" ("id" INTEGER PRIMARY KEY  NOT NULL ,"listing_id" integer,"created_at" datetime,"updated_at" datetime,"origin_url" varchar(255),"s3_url" varchar(255),"sizes" varchar(255) DEFAULT (null) )
       #}
      #execute %q{ 
        #INSERT INTO "main"."listing_images" SELECT "id","listing_id","created_at","updated_at","origin_url","s3_url","sizes" FROM "main"."oXHFcGcd04oXHFcGcd04_listing_images"
      #}
      #execute %q{
      #DROP TABLE "main"."oXHFcGcd04oXHFcGcd04_listing_images"
       #}
    #end
   remove_column :listing_images, :url
  end
end
