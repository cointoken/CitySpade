class Admin::InboxesController < Admin::BaseController
    before_action :set_inbox, only: [:show, :edit, :update, :destroy]
    before_filter :require_admin

    # GET /inboxes
    # GET /inboxes.json
    def index
      @inboxes = Inbox.all.order("#{sort_column} #{sort_direction}").page(params[:page]).per(10)
    end

    # GET /inboxes/1
    # GET /inboxes/1.json
    def show
    end

    # GET /inboxes/new
    def new
      @inbox = Inbox.new
    end

    # GET /inboxes/1/edit
    def edit
    end

    # POST /inboxes
    # POST /inboxes.json
    def create
      @inbox = Inbox.new(inbox_params)

      respond_to do |format|
        if @inbox.save
          format.html { redirect_to admin_inbox_path(@inbox), notice: 'Inbox was successfully created.' }
          format.json { render action: 'show', status: :created, location: @inbox }
        else
          format.html { render action: 'new' }
          format.json { render json: @inbox.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /inboxes/1
    # PATCH/PUT /inboxes/1.json
    def update
      respond_to do |format|
        if @inbox.update(inbox_params)
          format.html { redirect_to admin_inbox_path(@inbox), notice: 'Inbox was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: 'edit' }
          format.json { render json: @inbox.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /inboxes/1
    # DELETE /inboxes/1.json
    def destroy
      @inbox.destroy
      respond_to do |format|
        format.html { redirect_to admin_inboxes_url }
        format.json { head :no_content }
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_inbox
      @inbox = Inbox.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def inbox_params
      params.require(:inbox).permit(:title, :content, :account_id)
    end
  end
