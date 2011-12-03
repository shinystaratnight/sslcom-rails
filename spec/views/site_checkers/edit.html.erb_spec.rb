require 'spec_helper'

describe "site_checks/edit.html.erb" do
  before(:each) do
    @site_checker = assign(:site_checks, stub_model(SiteChecker))
  end

  it "renders the edit site_checker form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => site_checks_path(@site_checker), :method => "post" do
    end
  end
end
