class AddImageUrlsToBlogs < ActiveRecord::Migration
  def change
    add_column :blogs, :image_urls, :string
    Blog.init_image_urls
  end
end
