module BlogsHelper
  def permalink_for_blog(blog)
    release_time = blog.created_at
    year = release_time.strftime("%Y")
    month = release_time.strftime("%m")
    day = release_time.strftime("%d")
    day_blogs_path(year,month,day,blog.permalink)
  end
end
