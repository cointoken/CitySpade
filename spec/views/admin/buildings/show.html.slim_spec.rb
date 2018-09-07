require 'spec_helper'

describe "admin/buildings/show" do
  before(:each) do
    @admin_building = assign(:admin_building, stub_model(Admin::Building))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
