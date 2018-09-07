require 'spec_helper'

describe SearchController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index', title: 'soho', beds: 2, baths: 2.5, current_area: 'new-york'
      # response.should be_success
      listing = assigns(:listings).first
      (!!(listing.political_area.long_name =~ /soho/i || listing.formatted_address =~ /soho/i)).should eq(true)
      listing.beds.should eq(2)
      listing.baths.should eq(2.5)
    end
  end

end
