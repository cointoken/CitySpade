require 'spec_helper'
describe Api::V1::ListingsController do
  render_views
  let(:account) { create :account}
  before{ sign_in account}

  describe "GET 'index'" do
    let(:listings) do
      Listing.where(flag: 0, political_area_id: current_area.sub_ids).
        limit(2).order('listings.place_flag desc,id desc')
    end

    it "should return the list of listings" do
      api_get :index, limit: 2, rent: 0
      response.status.should == 200
      api_json.size.should == 2
      api_json.each_with_index do |json, index|
        json["id"].should == listings[index][:id]
      end
    end

  end

  describe "GET 'show'" do
    let(:listing){ Listing.first }

    it "should return the listing's details" do
      api_get :show, id: listing.id
      response.status.should == 200
      api_json["original_url"].should == listing[:origin_url]
    end
  end

  describe "POST 'collect'" do
    it "should collect a listing" do
      account.generate_api_key!
      api_post :collect, token: account.api_key, id: "1234"
      response.status.should == 200
    end

    it "should not collect a listing" do
      api_post :collect, token: " ", id: "1234"
      response.status.should == 401
    end
  end

  describe "DELETE 'uncollect'" do
    it "should uncollect a listing" do
      account.generate_api_key!
      api_delete :collect, token: account.api_key, id: "1234"
      response.status.should == 200
    end

    it "should not uncollect a listing" do
      api_delete :collect, token: "  ", id: "1234"
      response.status.should == 401
    end
  end
end
