require 'spec_helper'

describe Admin::WeekListingsController do
  let(:admin) {create :admin}
  describe "GET 'index'" do
    it "returns http success" do
      sign_in admin
      get 'index'
      response.should be_success
    end

    it 'redirect to root page when dont auth' do
      get 'index'
      response.redirect_url.should eq(root_url)
    end
  end

end
