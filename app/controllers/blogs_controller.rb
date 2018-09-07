class BlogsController < ApplicationController

  # caches_action :index, cache_path: Proc.new{|c| c.base_cache_params.merge({last_id: Blog.last.id}).merge(c.params)}
  # caches_action :show, cache_path: Proc.new{|c| c.base_cache_params}

  def index
    @page_size = Blog.all.size/3
    @blogs = Blog.order("created_at DESC").page(params[:page]).per(3)
    respond_to do |format|
      format.html # index.html.erb
      format.json  { render partial:'blogs' }
    end
  end

  def show
    @blog = Blog.find_permalink(params[:id])
    @show_detail = true
  end

end
