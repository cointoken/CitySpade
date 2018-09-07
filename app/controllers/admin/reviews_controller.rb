class Admin::ReviewsController < Admin::BaseController
  before_action :set_admin_review, only: [:show, :edit, :update, :destroy]
  before_filter :require_admin

  # GET /admin/reviews
  # GET /admin/reviews.json
  def index
    @reviews = Review.unscoped.all
    if params[:sort].blank?
      @reviews = @reviews.order('created_at desc').page(params[:page]).per(10)
    else
      @reviews = @reviews.unscoped.order("#{sort_column} #{sort_direction}").page(params[:page]).per(10)
    end
    @reviews = @reviews.where(status: params[:status]) unless params[:status].blank?
    @reviews = @reviews.where(id: params[:id]) unless params[:id].blank?
    @reviews = @reviews.where("address like ?", "%#{params[:address]}%") unless params[:address].blank?
    @reviews = @reviews.where("building_name like ?", "%#{params[:building_name]}%") unless params[:building_name].blank?
    @reviews = @reviews.where("city like ?", "%#{params[:city]}%") unless params[:city]
  end

  # GET /admin/reviews/1
  # GET /admin/reviews/1.json
  def show
  end

  # GET /admin/reviews/new
  def new
    @admin_review = Review.new
  end

  # GET /admin/reviews/1/edit
  def edit
  end

  # POST /admin/reviews
  # POST /admin/reviews.json
  def create
    @admin_review = Review.new(admin_review_params)

    respond_to do |format|
      if @admin_review.save
        format.html { redirect_to @admin_review, notice: 'Review was successfully created.' }
        format.json { render action: 'show', status: :created, location: @admin_review }
      else
        format.html { render action: 'new' }
        format.json { render json: @admin_review.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin/reviews/1
  # PATCH/PUT /admin/reviews/1.json
  def update
    respond_to do |format|
      if @admin_review.update(admin_review_params)
        format.html { redirect_to admin_reviews_path, notice: 'Review was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @admin_review.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/reviews/1
  # DELETE /admin/reviews/1.json
  def destroy
    @admin_review.destroy
    respond_to do |format|
      format.html { redirect_to admin_reviews_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_review
      @admin_review = Review.unscoped.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def admin_review_params
      params.require(:review).permit(:address, :building_name, :cross_street, :city, :state, :status, :comment)
    end
end
