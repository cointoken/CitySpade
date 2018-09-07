class AddVideoToListing < ActiveRecord::Migration
  def up
    add_column :listings, :video_url, :string
  end

  def down
    remove_column :listings, :video_url
  end
end
