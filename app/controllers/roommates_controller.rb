class RoommatesController < ApplicationController
  before_action :account_signed_in?, only: [:create, :update, :detroy, :new]

  def index
    sorted_roommates = Roommate.sort_by_created
    roommates =  Kaminari.paginate_array(sorted_roommates)
      .page(params[:page]).per(24)

    link_hash = {
      "All Posts" => roomsearch_path,
      "Room Offers" => rooms_path
    }

    render "room_search/_index_layout",
      locals: {
      total_post_count: sorted_roommates.count,
        posts: roommates,
        heading: "ROOMMATES",
        new_path: new_roommate_path,
        link_hash: link_hash
      }
  end

  def show
    @roommate = Roommate.find(params[:id])
    if @roommate.expired?
      flash[:notice] = "This roommate request may have expired"
    end
  end

  def new
    @roommate = Roommate.new
  end

  def create
    @roommate = current_account.roommates.new(roommate_params)
    photo_ids = params[:photo_ids]
    if photo_ids.present?
      photo_ids.split(',').each do |id|
        @roommate.photos << Photo.find(id) if id.present?
      end
    end
    if current_account.logined_facebook?
      if @roommate.save
        flash[:notice] = "New roommate offer posted"
        redirect_to @roommate
      else
        flash[:alert] = @roommate.errors.full_messages.join(", ")
        render :new
      end
    else
     flash[:alert] = "You must be signed into your facebook account!"
     render :new
    end
  end

  def edit
    @roommate = Roommate.find(params[:id])
    if current_account != @roommate.account
      redirect_to @room
      flash[:notice] = "oops something went wrong ¯\\_(ツ)_/¯"
    end
  end

  def expire
    @roommate = Roommate.find(params[:roommate_id])
    @roommate.expired!
    redirect_to roommates_path, notice: "Successfully expired roommate request"
  end

  def update
    @roommate = Roommate.find(params[:id])
    if @roommate.update(roommate_params)
      flash[:notice] = "Roommate offer updated"
      redirect_to @roommate
    else
      flash[:alert] = @roommate.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    @roommate = Roommate.find(params[:id])
    @roommate.destroy
    respond_to do |format|
      format.html { redirect_to roommates_url, notice: 'Roommate offer was successfully removed.' }
      format.json { head :no_content }
    end
  end

  def send_message
    id =  params[:roommate_id].split('-').first
    @roommate = Roommate.find id
    name = params[:Name]
    email = params[:Email]
    description = params[:Description]
    phone = params[:Phone]
    subject = "[CitySpade] #{name} is Interested in Being Your Roommate"
    body = "Contact Info:\nName: #{name}\nEmail: #{email}\n"
    if !phone.empty?
      body << "Phone: #{phone}\n"
    end
    body << "\n\n"
    RoomContactMailer.contact_email(email, subject, body,  description, @roommate).deliver
    @roommate.update_attributes(contacted: @roommate.contacted + 1)
    flash[:notice] =  "Message sent"
    redirect_to roommate_path params[:roommate_id]
  end

  protected

  def roommate_params
    params_hash = params.require(:roommate).permit(
      :gender, :budget, {pets_allowed: []}, {borough: []}, :about_me,
      :students_only, :raw_neighborhood,
      :title, :num_roommates, :location, :move_in_date,
      :duration
    )

    if params_hash[:budget].present?
      params_hash[:budget] =  params_hash[:budget].split(".")[0].gsub(/[^0-9]/,'')
    end

    params_hash[:borough] ||= []
    params_hash[:pets_allowed] ||= []

    params_hash
  end
end
