class AddVideoToPhotos < ActiveRecord::Migration
  def up
    add_column :photos, :video_url, :string, default: nil
  end
  def down
    remove_column :photos, :video_url
  end
end
