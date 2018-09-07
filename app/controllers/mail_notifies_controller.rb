class MailNotifiesController < ApplicationController
  before_action :get_account

  def unsubscribe
    if @account
      @account.mail_notify.update_attribute(:is_recommended, false)
    end
  end

  private

  def get_account
    @account = begin
      account = Account.where(email: params[:email]).first

      if account && account.hex_api_key_is?(params[:token])
        account
      else
        nil
      end
    end
  end
end
