class AccountInboxesController < ApplicationController
  before_action :set_account_inbox, only: [:destroy]

  def destroy
    @account_inbox.destroy
    respond_to do |format|
      format.html { redirect_to inboxes_url }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_inbox
    @account_inbox = AccountInbox.find(params[:id])
  end
end