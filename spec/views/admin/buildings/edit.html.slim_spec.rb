require 'spec_helper'

describe "admin/buildings/edit" do
  before(:each) do
    @admin_building = assign(:admin_building, stub_model(Admin::Building))
  end

  it "renders the edit admin_building form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", admin_building_path(@admin_building), "post" do
    end
  end
end
