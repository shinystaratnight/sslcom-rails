require 'spec_helper'

describe "site_checks/index.html.erb" do
  before(:each) do
    assign(:site_checks, [
      stub_model(SiteChecker),
      stub_model(SiteChecker)
    ])
  end

  it "renders a list of site_checks" do
    render
  end
end
