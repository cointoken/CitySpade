require "spec_helper"

describe Api::V1::AccountController do

  let(:account) { create :account }
  describe "GET 'savinglists'" do
    before{ sign_in  account}

    it "should save listings" do
      account.generate_api_key!
      api_get :savinglists, token: account.api_key
      response.status.should == 200
    end

    it "should not save listings" do
      api_get :savinglists, token: nil
      response.status.should == 401
    end
  end
end
