class Admin::PhotosController < Admin::BaseController
  before_filter :require_admin
  def index
    if request.post?
      if params[:image_ids]
        top_ids = params[:image_ids] & (params[:top_ids] || [])
        not_ids = params[:image_ids] - top_ids
        Photo.where(id: top_ids).update_all is_top: true if top_ids.present?
        Photo.where(id: not_ids).update_all is_top: false if not_ids.present?
      end
    end
    if params[:review_id].present?
      @object = Review.find(params[:review_id])
      @images = @review.venue.images.order("imageable_id = #{@review.id} desc").page params[:page]
    elsif params[:formatted_address].present?
      object = Venue.where('formatted_address like ?', "#{params[:formatted_address]}%")
      object = object.where(region_type: params[:region_type]) if params[:region_type]
      sqls = object.map{|s| "(imageable_id = #{s.id} and imageable_type='#{s.class.to_s}') or
                         (imageable_id in (#{s.reviews.pluck(:id).join(',')}) and imageable_type='Review')"}
      @images = Photo.unscoped.where(sqls.join(' or ')).page params[:page] if sqls.present?
    end
    @images ||= Photo.unscoped.where("imageable_type= ? or imageable_type = ?", 'Review', 'Venue').page params[:page]
  end

  def destroy
    @photo = Photo.find(params[:id])
    @photo.destroy
    respond_to do |format|
      format.html { redirect_to admin_venues_url }
      format.json { head :no_content }
    end
  end
end
