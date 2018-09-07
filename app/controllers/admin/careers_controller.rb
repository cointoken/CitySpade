class Admin::CareersController < Admin::BaseController
  def index
    @careers = Career.all
  end

  def show
    @career = Career.find params[:id]
  end

  def new
    @career = Career.new
  end

  def edit
    @career = Career.find params[:id]
  end

  def update
    @career = Career.find params[:id]
    @career.update(career_params)
    respond_to do |format|
      if @career.save
        format.html{ redirect_to edit_admin_career_path, notice: 'Update success!!'}
      else
        format.html{ redirect_to edit_admin_career_path, notice: 'Failed'}
      end
    end
  end

  def create
    @career = Career.new(career_params)
    respond_to do |format|
      if @career.save
        format.html{redirect_to admin_careers_path, notice: 'Career created!'}
      else
        format.html{redirect_to admin_careers_path, notice: "failed to create"}
      end
    end
  end

  def destroy
    @career = Career.find params[:id]
    @career.destroy
    respond_to do |format|
      format.html{ redirect_to admin_careers_path, notice: "Deleted"}      
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def career_params
      params.require(:career).permit(:title, :location, :description, :job_type, :open)
    end
end
