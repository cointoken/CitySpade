class BuildingPagesController < ApplicationController
  before_action :force_json, only: :search
  include BuildingPagesHelper

  def index
    per_page = 8
    #page = params[:page]
    #last_page = SearchHelper.check_page_no(page, @buildings, per_page)
    #if page.to_i > last_page
    #  render file: "#{Rails.root}/public/404",layout: false, status: 404
    #else
    #@buildings = Building.all.sort_by{ |build| build.haveop ? 0 : 1}
    @buildings = Building.all.order(haveop: :desc)
    if params[:location]
      @buildings = location_search(params[:location], @buildings)
    end
    if params[:school]
      @buildings = school_search(params[:school])
    end
    if params[:search]
      @buildings = price_search(params[:search][:min], params[:search][:max], @buildings)
    end
    @buildings = @buildings.page(params[:page]).per(per_page)
    #end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @building =  Building.friendly.find params[:id]
    @images = @building.building_images
    @cover = @images.find_by(cover: true)
    @floorplans = @building.floorplans
    @studios = @floorplans.where(beds: 0)
    @beds1 = @floorplans.where(beds: 1)
    @beds2 = @floorplans.where(beds: 2)
    @beds3 = @floorplans.where(beds: 3)
    @start_price = @building.floorplans.minimum(:price)
    @listing = @building.closest_listing
  end

  def search
    @buildings = Building.all
    if params[:search]
      @buildings = @buildings.where('name LIKE ? or formatted_address LIKE ?', "%#{params[:search]}%","%#{params[:search]}%")
    end
    @buildings = @buildings.limit(8)
    #render json: @buildings.map{|b| "#{b.name}, #{b.formatted_address}"}
  end

  def send_message
    @building = Building.find params[:building_page_id]
    respond_to do |format|
      if ContactMailer.send_availability(msg_params, @building).deliver
        format.js
      else
        format.html
      end
    end
  end

  def favorite
    @building = Building.find(params[:building_id])
    if current_account.building_faved? @building
      reputation = current_account.get_building_faved(@building)
      reputation.destroy
      respond_to do |format|
        format.html {redirect_to building_page_path(@building), flash: {notice: "Removed from your wishlist"}}
      end
    else
      Reputation.create({reputable: @building, category: 'building', account_id: current_account.id})
      respond_to do |format|
        format.html {redirect_to building_page_path(@building), flash: {notice: "Added to your wishlist"}}
      end
    end
  end

  private

  def force_json
    request.format = :json
  end

  def msg_params
    params.permit(:fname, :lname, :email, :wechat, :message)
  end

end
