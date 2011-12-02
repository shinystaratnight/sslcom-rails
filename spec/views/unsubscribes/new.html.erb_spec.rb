require 'spec_helper'

describe "unsubscribes/new.html.erb" do
  before(:each) do
    assign(:unsubscribe, stub_model(Unsubscribe).as_new_record)
  end

  it "renders new unsubscribe form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => unsubscribes_path, :method => "post" do
    end
  end
end
