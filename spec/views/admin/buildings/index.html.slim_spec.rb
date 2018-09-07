require 'spec_helper'

describe "admin/buildings/index" do
  before(:each) do
    assign(:admin_buildings, [
      stub_model(Admin::Building),
      stub_model(Admin::Building)
    ])
  end

  it "renders a list of admin/buildings" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
