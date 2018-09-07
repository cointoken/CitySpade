class Admin::SearchRecordsController < Admin::BaseController
  before_filter :require_admin
  def index
    @search_records = SearchRecord.all
    @search_records = SearchRecord.where(current_area: params[:current_area]) if params[:current_area].present?
    @search_records = @search_records.where("title like ?", "%#{params[:title]}%") if params[:title].present?
    @search_records = @search_records.where(flag: params[:flag]) if !params[:flag].blank? && ['rent', 'sale'].any?{|flag| params[:flag].include? flag}
    if params[:sort].blank?
      @search_records = @search_records.order(id: :desc).page(params[:page])
    else
      @search_records = @search_records.order("#{sort_column} #{sort_direction}").page(params[:page])
    end
  end

  def destroy
    @search_records = SearchRecord.find(params[:id]).destroy
    redirect_to admin_search_records_path
  end
end
