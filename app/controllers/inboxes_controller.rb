class InboxesController < ApplicationController
  before_action :set_inbox, only: [:show, :edit, :update, :destroy]

  # GET /inboxes
  # GET /inboxes.json
  def index
    # @inboxes = current_account.try(:inboxes) || Inbox.all 
    @account_inboxes = current_account.account_inboxes.page(params[:page]).per(6)
  end

  # GET /inboxes/1
  # GET /inboxes/1.json
  def show
    @account_inbox.read_inbox  
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inbox
      @inbox = Inbox.find(params[:id])
      @account_inbox = @inbox.account_inboxes.find_by_account_id(current_account.id)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def inbox_params
      params.require(:inbox).permit(:title, :content)
    end
end
