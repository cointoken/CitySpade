class ChangeBlogsImageUrls < ActiveRecord::Migration
  def change
    change_column :blogs, :image_urls, :string, limit: 2000
  end
end
