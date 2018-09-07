class Admin::BlogsController < Admin::BaseController
  before_action :set_blog, only: [:edit, :update, :destroy]
  before_filter :require_admin

  def index
    @blogs = Blog.all
    @blogs = Blog.where("title like ?", "%#{params[:title]}%") unless params[:title].blank?
    unless params[:author_name].blank?
      accounts = Account.all
      accounts = accounts.where("first_name like ? or last_name like ?", "%#{params[:author_name]}%", "%#{params[:author_name]}%")
      @blogs = Blog.where(account_id: accounts.map(&:id))
    end
    @blogs = @blogs.order("#{sort_column} #{sort_direction}").page(params[:page]).per(10)
  end

  def new
    @blog = Blog.new
  end

  def edit
  end

  def create
    @blog = current_account.blogs.new(blog_params)

    respond_to do |format|
      if @blog.save
        format.html { redirect_to @blog, notice: 'Blog was successfully created.' }
        format.json { render action: 'show', status: :created, location: @blog }
      else
        format.html { render action: 'new' }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @blog.update(blog_params)
        format.html { redirect_to @blog, notice: 'Blog was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @blog.destroy
    respond_to do |format|
      format.html { redirect_to admin_blogs_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blog
      @blog = Blog.find_permalink(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def blog_params
      params.require(:blog).permit(:title, :content, :account_id)
    end
end
