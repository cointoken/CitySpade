require 'spec_helper'

describe MlsController do

  render_views
  describe "GET 'index'" do
    it "returns http success" do
      mls = MlsInfo.order('rand()').first
      get 'index', mls_name: mls.name, broker_name: (mls.broker.try(:client_id)||mls.broker_name), mls_id: mls.mls_id
      response.code.should eq('302')
    end
  end

  describe "GET 'status'" do
    it 'returns http success' do
      get 'status', mls_name: 'RealtyMx'
      response.should be_success
    end
  end
end
