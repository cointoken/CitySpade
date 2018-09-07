class Admin::SearchForMesController < Admin::BaseController
  before_filter :require_marketing
  def index
    name = params[:name]
    email = params[:email]
    wechat = params[:wechat]
    email_valid = params[:email_valid]
    @form = SearchForMe.all
    @count = @form.count
    if name || email || wechat || email_valid
      @form = @form.where("email like ?", "%#{email}%") unless email.blank?
      @form = @form.where("name like ?", "%#{name}%") unless name.blank?
      @form = @form.where.not(wechat: nil) unless wechat.nil?
      if email_valid
        @form = @form.where(email_valid: true)
      end
    end
    @form  = @form.order(id: :desc).page params[:page]
    respond_to do |format|
      format.html
      format.csv {send_data SearchForMe.all.order(id: :desc).to_csv}
    end
  end

  def destroy
    @form = SearchForMe.find params[:id]
    @form.destroy
    respond_to do |format|
      format.html { redirect_to admin_search_for_mes_path, notice: 'Entry was successfully removed.'}
    end
  end

  def send_email
    SearchForMe.all.each do |client|
      RoomContactMailer.delay.building_suggestion(client)
    end
    respond_to do |format|
      format.html { redirect_to admin_search_for_mes_path, notice: 'All emails sent.'}
    end
  end

end
