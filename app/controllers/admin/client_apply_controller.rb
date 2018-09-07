class Admin::ClientApplyController < Admin::BaseController
  before_filter :require_operations
  def index
    fname = params[:first_name]
    lname = params[:last_name]
    email = params[:email]
    building = params[:building]
    @form = ClientApply.all
    if fname || lname || email || building
      @form = @form.where("first_name like ?", "%#{fname}%") unless fname.blank?
      @form = @form.where("last_name like ?", "%#{lname}%") unless lname.blank?
      @form = @form.where("email like ?", "%#{email}%") unless email.blank?
      @form = @form.where("building like ?", "%#{building}%") unless building.blank?
    end
    @form = @form.order(id: :desc).page(params[:page]).per(10)
    respond_to do |format|
      format.html
      format.csv {send_data ClientApply.all.order(id: :desc).to_csv}
    end
  end

  def edit
    @update_flag = true
    @application = ClientApply.find params[:id]
    @documents = @application.documents
  end

  def destroy
    @client = ClientApply.find params[:id]
    if @client.destroy
      redirect_to admin_client_apply_index_path, notice: 'Application was successfully deleted.'
    else
      redirect_to :back, notice: 'Something went wrong'
    end
  end

  def mail_template
    @client = ClientApply.find params[:client_id]
    @docs = @client.documents
  end

  def mail_building
    docs = params[:mail_build][:client_docs].first.split(",")
    fsize = 0
    docs.each do |doc_id|
      fsize += Document.find(doc_id).file_size
    end
    if 10.0 > fsize
      ContactMailer.delay.send_mail_building(params[:mail_build], docs)
      redirect_to admin_client_apply_index_path, notice: "Email sent successfully"
    else
      redirect_to :back, alert: "Cannot send attachments greater than 10MB"
    end
  end

  ## Generate query based on email & building for autocomplete
  def autocomplete
    query = params[:query]
    @emails =  ContactEmail.where("email LIKE ? OR building LIKE ?", "%#{query}%", "%#{query}%")
    render json: @emails
  end

  def update
    form = ClientApply.find params[:id]
    respond_to do |format|
      if form.update(admin_client_apply_paramas)
        format.html { redirect_to admin_client_apply_index_path }
        format.json { head :no_content }
      end
    end
  end

  def doc_size
    @size = Document.find(params[:id]).file_size
    render json: @size
  end

  def change_app_status
    @form = ClientApply.find params[:id]
    @form.app_status = params[:status]
    respond_to do |format|
      if @form.save
        format.json {render json: @form.app_status }
      end
    end
  end


  private

  def admin_client_apply_paramas
    params.require(:client_apply).permit(:dob, :ssn, :current_addr, :current_landlord, :current_landlord_ph, :current_rent, :position, :company, :start_date, :salary, :referral, :ref_info, :pet, :breed, :pet_age, :pet_age, :pet_weight, :emergency_name, :emergency_addr, :emergency_phone, :emergency_relation, :building, :unit, :agency)
  end

end
