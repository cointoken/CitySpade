class  Admin::PageViewsController <  Admin::BaseController
  before_filter :require_admin
  def index
    @page_views = PageView.all.order("#{sort_column} #{sort_direction}")
    @page_views = @page_views.where(page_type: params[:page_type] || "ContactAgent")
    @page_views = @page_views.where(page_id: params[:page_id].to_i) if params[:page_id].present?
    if params[:street_address].present? || params[:flag].present?
      listings = Listing.all
      listings = listings.where("formatted_address like ?", "%#{params[:street_address]}%") if params[:street_address].present?
      listings = listings.where(flag: params[:flag]) if params[:flag].present?
      @page_views = @page_views.where(page_id: listings.pluck(:id))
    end
    @page_views = @page_views.page params[:page]
  end
end
