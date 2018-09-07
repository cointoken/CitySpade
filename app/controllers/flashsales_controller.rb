class FlashsalesController < ApplicationController

  def index
    if params[:sort].present?
      @listings = sort_list(params[:sort]).order(video_url: :desc)
    else
      @listings = get_flash_listing.order(video_url: :desc)
    end
    per_page = 60
    page = params[:page]
    last_page = SearchHelper.check_page_no(page, @listings, per_page)
    if page.to_i > last_page
      render file: "#{Rails.root}/public/404",layout: false, status: 404
    else
      @listings = @listings.page(params[:page]).per(per_page)
    end
  end


  private

  def sort_list(sort)
    boroughs = ["Manhattan", "Brooklyn", "Queens", "Jersey City"]
    sort = sort.titleize
    if boroughs.include? sort
      flash_listings = get_flash_listing
      areas = PoliticalArea.where(long_name: sort)
      ids = areas.each.map { |x| x.sub_ids }
      ids << areas.ids
      ids.flatten!
      listings = flash_listings.where(political_area_id: ids)
    else
      listings = get_flash_listing
    end

  end

  def get_flash_listing
    Listing.where(is_flash_sale: true, status: 0)
  end

end
