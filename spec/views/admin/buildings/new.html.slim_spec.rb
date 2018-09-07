require 'spec_helper'

describe "admin/buildings/new" do
  before(:each) do
    assign(:admin_building, stub_model(Admin::Building).as_new_record)
  end

  it "renders new admin_building form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", admin_buildings_path, "post" do
    end
  end
end
