class PhotosController < ApplicationController
  before_action :set_photo, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :uploadify]

  # GET /photos
  # GET /photos.json
  def index
    # @photos = Photo.all
  end

  # GET /photos/1
  # GET /photos/1.json
  def show
  end

  # GET /photos/new
  def new
    @photo = Photo.new
  end

  # GET /photos/1/edit
  def edit
  end

  def uploadify
    if Object.const_defined?("Photo::#{params[:obj_name].classify}")
      kclass = Object.const_get "Photo::#{params[:obj_name].classify}"
    else
      kclass = Photo
    end
    if params[:obj_id].present? && params[:obj_id] =~ /^\d+/
      photo = kclass.new image: params[:Filedata], review_token: account_token, imageable_id: params[:obj_id], imageable_type: params[:obj_name].classify
    else
      photo = kclass.new image: params[:Filedata], review_token: account_token, imageable_type: params[:obj_name].classify
    end
    if photo.save
      render json: {small_url: photo.image.small.url, delete_url: photo_path(photo), url: photo.image.url, id: photo.id}
    else
      render json: photo.errors, status: 500
    end
  end

  # POST /photos
  # POST /photos.json
  def create
    # @photo = Photo.new(photo_params)
    photo_params[:image] = photo_params[:image].first if photo_params[:image].class == Array
    if params[:review_id]
      @review = Review.find(params[:review_id])
      @photo = @review.photos.build(photo_params)
    else
      @photo = Photo.new(photo_params.permit(:image,:review_token))
    end

    respond_to do |format|
      if @photo.save
        format.html {
          render :json => @photo.to_jq_upload,
          :content_type => 'text/html',
          :layout => false
        }
        format.json {
          render :json => @photo.to_jq_upload
        }
      else
        format.html { render action: 'new' }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /photos/1
  # PATCH/PUT /photos/1.json
  def update
    respond_to do |format|
      if @photo.update(photo_params)
        format.html { redirect_to @photo, notice: 'Photo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end

  def uploaded_photos
    if session[:review_token].present?
      @photos = Photo.where review_token: session[:review_token]
      files = []
      @photos.each do |ph|
        files << ph.to_json_image
      end
      render json: {files: files}
    else
      render json: {files:[]}
    end
  end

  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    if current_account && @photo.imageable
      if current_account == @photo.imageable.account
        @photo.destroy
      end
    else
      if account_token == @photo.review_token
        @photo.destroy
      end
    end
    @photo.destroy #if @photo.review_token == params[:review_token]
    respond_to do |format|
      # format.html { redirect_to photos_url }
      format.json { head :no_content }
    end
  end
  def photos_info
      if params[:obj_id].present?
        # case params[:obj_type]
        # when "Sublet" 
        #   sublet = Sublet.find params[:obj_id]
        #   photos = sublet.photos
        # when "Review"
        #   review = Review.find params[:obj_id]
        #   photos = review.photos
        # end
        photos = Photo.where(imageable_id: params[:obj_id], imageable_type: params[:obj_type])
      else
        photos = Photo.where(review_token: account_token, imageable_id: nil).where('created_at > ?', Time.now - 1.day)
      end
      @photos_json = photos.map{|s| {small_url: s.image.small.url, delete_url: photo_path(s, token: s.token), id: s.id}}.to_json
  end
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_photo
      @photo = Photo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def photo_params
      params.require(:photo)
    end
end
