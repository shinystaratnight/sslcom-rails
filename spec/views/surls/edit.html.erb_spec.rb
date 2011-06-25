require 'spec_helper'

describe "surls/edit.html.erb" do
  before(:each) do
    @surl = assign(:surl, stub_model(Surl))
  end

  it "renders the edit surl form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => surls_path(@surl), :method => "post" do
    end
  end
end
