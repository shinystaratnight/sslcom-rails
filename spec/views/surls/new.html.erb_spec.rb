require 'spec_helper'

describe "surls/new.html.erb" do
  before(:each) do
    assign(:surl, stub_model(Surl).as_new_record)
  end

  it "renders new surl form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => surls_path, :method => "post" do
    end
  end
end
