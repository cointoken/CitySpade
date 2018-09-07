class RoomsController < ApplicationController
  before_action :authenticate_account!, except: [:index, :show, :new]
  before_action :account_signed_in?, only: [:create, :update, :destroy]
  before_action :set_custom_formId, only: [:new, :edit, :create, :update]

  def index
    sorted_rooms = Room.sort_by_created
    rooms =  Kaminari.paginate_array(sorted_rooms)
                        .page(params[:page]).per(24)

    link_hash = {
      "All Posts" => roomsearch_path,
      "Roommates" => roommates_path
    }

    render "room_search/_index_layout",
      locals: {
        total_post_count: sorted_rooms.count,
        posts: rooms,
        heading: "ROOM OFFERS",
        new_path: new_room_path,
        link_hash: link_hash
      }
  end

  def show
    @room = Room.find(params[:id])
    @subway_marker = @room.closest_listing
    if @room.expired?
      flash[:notice] = "This room offer may have expired"
    end
  end

  def new
    #gon.ajax_urls = Array(gon.ajax_urls) << photos_info_photos_path

    @room = Room.new
    @room_detail = RoomDetail.new
  end

  def edit
    @room = Room.find(params[:id])
    @room_detail = @room.room_detail

    if current_account != @room.account
      redirect_to @room
      flash[:notice] = "oops something went wrong ¯\\_(ツ)_/¯"
    end

    @images = @room.photos.map(&:image)

    #gon.ajax_urls = Array(gon.ajax_urls) << photos_info_photos_path(
    #  obj_type: controller_name.classify,
    #  obj_id: params[:id]
    #)
  end

  def create
    @room = current_account.rooms.new(room_params)
    @room_detail = @room.room_detail

    photo_ids = params[:photo_ids]

    if photo_ids.present?
      photo_ids.split(',').each do |id|
        @room.photos << Photo.find(id) if id.present?
      end
    end

    if current_account.logined_facebook?
      if @room.save
        flash[:notice] = "New room offer posted"
        redirect_to @room
      else
        flash[:alert] = @room.errors.full_messages.join(", ")
        render :new
      end

    else
      flash[:alert] = "You must be signed into your facebook account!"
      render :new
    end
  end

  def update
    @room = Room.find(params[:id])
    if @room.update(room_params)
      flash[:notice] = "Room offer updated"
      redirect_to @room
    else
      flash[:alert] = @room.errors.full_messages.join(", ")
      redirect_to :back
    end
  end

  def expire
    @room = Room.find(params[:room_id])
    @room.expired!
    redirect_to rooms_path, notice: "Successfully expired Room Offer"
  end

  def destroy
    @room = Room.find(params[:id])
    @room.destroy
    respond_to do |format|
      format.html { redirect_to rooms_url, notice: 'Room offer was successfully removed.' }
      format.json { head :no_content }
    end
  end

  def send_message
    id =  params[:room_id].split('-').first
    @room = Room.find id
    name = params[:Name]
    email = params[:Email]
    description = params[:Description]
    phone = params[:Phone]
    subject = "[CitySpade] #{name} is Interested in Subletting Your Room"
    body = "Contact Info:\nName: #{name}\nEmail: #{email}\n"
    if !phone.empty?
      body << "Phone: #{phone}\n"
    end
    body << "\n\n"
    RoomContactMailer.contact_email(email, subject, body,  description, @room).deliver
    @room.update_attributes(contacted: @room.contacted + 1)
    flash[:notice] =  "Message sent"
    redirect_to room_path params[:room_id]
  end

  def save_wishlist
    @room = Room.find(params[:room_id])
    if current_account.room_saved? @room
      reputation = current_account.get_room_saved(@room)
      reputation.destroy
      respond_to do |format|
        format.html { redirect_to @room, flash: {notice:"Removed from your account"}}
      end
    elsif
      Reputation.create({reputable: @room, category: 'room', account_id: current_account.id})
      respond_to do |format|
        format.html { redirect_to @room, flash: {notice: "Saved to your account"}}
      end
    end
  end

  protected
  def room_params
    params_hash = params.require(:room).permit(
      :room_type, :title, :street_address, :city, :zipcode, :bedrooms,
      :bathrooms, :available_begin_at, :available_end_at, :state, :price_month,
      :rooms_available, :photos,
      :room_detail_attributes => [
        {:amenities => []},
        {:pets_allowed => []},
        :description
      ]
    )

    params_hash[:price_month] = params_hash[:price_month].split(".")[0].gsub(/[^0-9]/,'')
    params_hash
  end

  private
  def set_custom_formId
    gon.imageFormId = "#roomImageForm"
  end
end
