class RentaldealsController < ApplicationController
  helper_method :check_cookie
  before_filter :get_details
  before_action :get_listings, only: [:book_showing]
  #before_action :get_indexes, only: [:cookie_listings]

  #def index
  #  @rental_deals = Agent.find_by(email: "cityspade@gmail.com").listings.limit(2)
  #  @discounted_listing = Listing.last
  #end

  def all_deals
    ids = [333621]
    @buildings = Building.find(ids)
    @building_names = ['The Sky']
    @deal_msgs = ['One month free on 13 month lease']
    @images_list = [653870]
    if check_cookie
      @cookies = cookies[:listing_ids].split(",")
    end
  end

  def book_showing
    @booking = BookShowing.new(client_params)
    respond_to do |format|
      if @listings
        if params.has_key?(:date) && params.has_key?(:time)
          @date = ShowingDate.find_or_create_by(date: Date.strptime(params.require(:date), '%m/%d/%Y'))
          @time = ShowingTimeSlot.find(params.require(:time))
        end
        @booking.show_date = @date
        @booking.time_slot = @time
        if @booking.save
          RoomContactMailer.book_showing_email(@booking, @listings, @info).deliver
          format.html
          format.js
        else
          format.html { render partial: 'form' }
        end
      else
        format.html { render partial: 'form' }
      end
    end
  end

  def cookie_listings
    all_ids = params[:ids]
    @listings=[]
    all_ids.each do |x|
      @listings << Listing.find(x)
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def client_params
    params.permit(:name, :email)
  end

  def check_cookie
    if cookies[:listing_ids].blank?
      return false
    else
      return true
    end
  end

  def get_listings
    if check_cookie
      ids = cookies[:listing_ids].split(",")
      @listings = []
      ids.each do |x|
        @listings << Listing.find(x)
      end
    end
  end

  def get_details
    @info = Hash.new
    @info[:units] = ['60N', '55S', '31E', '59D', '56Q', '39K']
    @info[:beds] = [2,1,1,0,0,0]
    @info[:baths] = [2,1,1,1,1,1]
    @info[:prices] = [7450, 6090, 4380, 3715, 3860, 3365]
    @info[:list_ids] = get_indexes
  end

  def get_indexes
    b_ids = [333621]
    @list_ids =[]
    buildings = Building.find(b_ids)
    buildings.each do |building|
      building.listings.limit(6). each do |list|
        @list_ids << list.id
      end
    end
    @list_ids
  end

end
