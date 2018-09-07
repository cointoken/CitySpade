class Admin::SpadePassesController < Admin::BaseController
  before_action :set_spade_pass, only: [:show, :edit, :update, :destroy, :add_images, :create_images]

  def add_images
  end

  def create_images
    if params[:spade_pass]
      save_data(@spade_pass)
      if @spade_pass.save
        flash[:notice] = "Saved successfully"
        redirect_to admin_spade_passes_path
      else
        flash[:alert] = "Something went wrong."
        redirect_to add_images_admin_spade_pass_path
      end
    else
      flash[:alert] = "Please add Images before submitting."
      redirect_to add_images_admin_spade_pass_path
    end
  end

  def show
  end

  def index
    @spade_passes = SpadePass.order(rank: :asc).page(params[:page]).per(10)
  end

  def new
    @spade_pass = SpadePass.new
  end

  def edit
  end

  def update
    respond_to do |format|
      if @spade_pass.update(spade_pass_params)
        format.html { redirect_to admin_spade_passes_url, notice: 'SpadePass was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @spade_pass.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @spade_pass = current_account.spade_passes.new(spade_pass_params)

    respond_to do |format|
      if @spade_pass.save
        format.html { redirect_to admin_spade_passes_url, notice: 'SpadePass was successfully created.' }
        format.json { render action: 'show', status: :created, location: @spade_pass }
      else
        format.html { render action: 'new' }
        format.json { render json: @spade_pass.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @spade_pass.destroy
    respond_to do |format|
      format.html { redirect_to admin_spade_passes_url }
      format.json { head :no_content }
    end
  end

  def delete_image
    sp_image = SpadePassImage.find params[:id]
    spade_pass_id = sp_image.spade_pass_id
    if sp_image.destroy
      flash[:notice] = "Removed successfully"
    else
      flash[:alert] = "Something went wrong"
    end
    redirect_to add_images_admin_spade_pass_path(spade_pass_id)
  end

  def set_cover
    sp_image = SpadePassImage.find params[:id]
    sp_image.cover = true
    if sp_image.save
      redirect_to :back, notice: "Image set as cover"
    else
      redirect_to :back, alert: "Something went wrong"
    end
  end

  private
    def set_spade_pass
      @spade_pass = SpadePass.find(params[:id])
    end


    def spade_pass_params
      params.require(:spade_pass).permit(:title, :formatted_address, :street_address, :account_id, :description, :rank,
                                         :city, :borough, :zipcode, :spade_pass_type, :special_offers, :contact_tel, :is_recommended, :discounts_expired_date)
    end

    def spade_pass_images_params
      params.require(:spade_pass).require(:spade_pass_images_attributes).permit( image: [])
    end

    def save_data(spade_pass)
      spade_pass_images_params.each do | key, val|
        val.each do |img|
          spade_pass.spade_pass_images << SpadePassImage.new(image: img)
        end
      end
    end

end
