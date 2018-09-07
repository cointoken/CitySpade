require 'spec_helper'

describe MailNotifiesController do
  let(:account) {create :account}
  render_views

  describe "GET 'unsubscribe'" do
    it "returns http success" do
      mail_notify = account.mail_notify || account.create_mail_notify
      mail_notify.update_columns is_recommended: true

      get 'unsubscribe', email: account.email, token: account.hex_api_key
      response.should be_success
      mail_notify.reload.is_recommended.should eq(false)
    end
  end

end
