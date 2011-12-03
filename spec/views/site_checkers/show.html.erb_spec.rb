require 'spec_helper'

describe "site_checks/show.html.erb" do
  before(:each) do
    @site_checker = assign(:site_checks, stub_model(SiteChecker))
  end

  it "renders attributes in <p>" do
    render
  end
end
