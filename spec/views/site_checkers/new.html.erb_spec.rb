require 'spec_helper'

describe "site_checks/new.html.erb" do
  before(:each) do
    assign(:site_checker, stub_model(SiteChecker).as_new_record)
  end

  it "renders new site_checker form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => site_checks_path, :method => "post" do
    end
  end
end
