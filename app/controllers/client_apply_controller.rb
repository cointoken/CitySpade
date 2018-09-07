class ClientApplyController < ApplicationController
  before_filter :set_locale
  before_action :get_curr_address, only: [:create]

  def new
    @application = ClientApply.new
    if current_account.present?
      @application.account_id = current_account.id
    end
    @application.documents.build
  end

  def create
    @application = ClientApply.new(apply_params)
    @application.account_id = current_account.id
    if params[:client_apply][:documents_attributes]
      create_docs(@application)
    end
    if @application.save
      redirect_to apply_confirm_path(@application)
      RoomContactMailer.token_confirm(@application).deliver
      mail = RoomContactMailer.client_application(@application)
      mail.deliver
    else
      flash.now[:alert] = "Something went wrong."
      render :new
    end
    #mail = RoomContactMailer.client_application(info)
    #if mail.deliver
    #  redirect_to apply_confirm_path
    #else
    #  render :new
    #end
  end

  def show
    @application = ClientApply.find params[:id]
  end

  def retrieve
  end

  def edit
    @update_flag = true
    token = params[:token]
    dob = Date.strptime(params[:dob], "%m/%d/%Y") rescue nil
    email = params[:email]
    @application = ClientApply.find_by(access_token: token, dob: dob, email: email)
    respond_to do |format|
      if @application
        @documents = @application.documents
        format.js {}
        #format.json { render json: @documents }
      else
        @error = true
        format.js {
          flash.now[:alert] = "Please enter valid credentials"
        }
      end
    end
    #if @application
    #  @documents = @application.documents
    #  render json: @documents
    #end
  end

  def update
    id = params[:client_apply][:id]
    if params[:client_apply][:documents_attributes]
      @application = ClientApply.find(id)
      create_docs(@application)
    end
    flash[:notice] = "Updated successfully."
    redirect_to apply_retrieve_path
  end

  def destroy
    @document = Document.find params[:id]
    client_id = @document.client_id
    @document.destroy
    @application = ClientApply.find(client_id)
    @documents = @application.documents
    @update_flag = true
    respond_to do |format|
      format.html { redirect_to apply_retrieve_path }
      format.js { flash.now[:notice] = "Deleted file succesfully."}
    end
  end

  def app_fee
    gon.deposit = false
    @application = ClientApply.find params[:id]
  end

  def card_payment

    respond_to do |format|
      begin
        @resp = charge_card(10000)
        client = ClientApply.find params[:id]
        client.update_attribute(:paid, true)
        ContactMailer.send_receipt(client, @resp, "Application Fee Receipt").deliver
        format.js
        format.json
      rescue SquareConnect::ApiError => e
        #render json: { status: 400, errors: JSON.parse(e.response_body)["errors"]}
        format.js { flash[:error] = JSON.parse(e.response_body)["errors"] }
      end
    end

  end

  def deposit
    gon.deposit = true
    @application = ClientApply.find params[:id]
  end

  def deposit_payment
    gon.deposit = true
    amount = params[:amt].to_f * 100
    respond_to do |format|
      begin
        @resp = charge_card(amount.to_i)
        client = ClientApply.find params[:id]
        client.update_attribute(:deposit, params[:amt])
        ContactMailer.send_receipt(client, @resp, "Deposit Payment Receipt").deliver
        format.js
        format.json
      rescue SquareConnect::ApiError => e
        #render json: { status: 400, errors: JSON.parse(e.response_body)["errors"]}
        format.js { flash[:error] = JSON.parse(e.response_body)["errors"] }
      end
    end

  end

  def cute_divide
    gon.cutedivide = true
    @client = Cutedivide.new
  end

  def cutedivide_payment
    amount = params[:client][:amount].to_f * 100
    respond_to do |format|
      begin
        @client = Cutedivide.new(cutedivide_params)
        if (@resp = charge_card(amount.to_i)) && @client.save
          @client.transact_id = @resp.transaction.id
          @client.save
          ContactMailer.send_receipt(@client, @resp, "Cutedivide Payment Receipt").deliver
          ContactMailer.send_cutedivide(@client).deliver
          format.js
          format.json
        else
          format.js { flash.now[:alert] = "Something went wrong." }
        end
      rescue SquareConnect::ApiError => e
        format.js { flash[:error] = JSON.parse(e.response_body)["errors"] }
      end
    end
  end


  private

  def apply_params
    params.require(:client_apply).permit(:first_name, :last_name, :dob, :phone, :email, :ssn, :building, :unit, :current_addr, :current_landlord, :current_landlord_ph, :current_rent, :position, :company, :start_date, :salary, :pet, :breed, :pet_name, :pet_age, :pet_weight, :emergency_name, :emergency_addr, :emergency_phone, :emergency_relation, :referral, :ref_info, :is_employed, :residency, :agency, :account_id, status:[])
  end

  def doc_params
    params.require(:client_apply).require(:documents_attributes).permit(photo_id: [], bank_statement: [], school_letter: [], paystub: [], passport: [], visa: [], i20: [], green_card: [], opt: [], h1b: [], other: [])
  end

  def cutedivide_params
    params.require(:client).permit(:name, :email, :phone, :building, :unit, :wechat, :amount)
  end

  def get_curr_address
    x = params[:client_apply]
    addr = [x[:curr_street], x[:curr_city], x[:curr_state], x[:curr_country], x[:curr_zip]]
    x[:current_addr] = addr.reject(&:empty?).join(",")
  end

  def create_docs(application)
    doc_params.each do |key, val|
      val.each do |doc|
        application.documents << Document.new(name: doc, doc_type: key)
      end
    end
  end

  def set_locale
    if params[:locale].present?
      I18n.locale = params[:locale]
    else
      I18n.locale = 'ch'
    end
  end

  def charge_card(amount)
    if Rails.env == "development"
      if gon.deposit
        token = Settings.square.development.escrow_token
      else
        token = Settings.square.development.access_token
      end
    else
      if gon.deposit
        token = Settings.square.production.escrow_token
      else
        token = Settings.square.production.access_token
      end
    end
    SquareConnect.configure do |config|
      config.access_token = token
    end
    transaction_api = SquareConnect::TransactionsApi.new
    request_body = {
      :card_nonce => params[:card_nonce],
      :amount_money => {
        :amount => amount,
        :currency => 'USD'
      },
      :idempotency_key => SecureRandom.uuid
    }

    locationApi = SquareConnect::LocationsApi.new
    locations = locationApi.list_locations
    response = transaction_api.charge(locations.locations[0].id, request_body)
    return response
  end

end
