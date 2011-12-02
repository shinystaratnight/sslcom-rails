require 'spec_helper'

describe "unsubscribes/edit.html.erb" do
  before(:each) do
    @unsubscribe = assign(:unsubscribe, stub_model(Unsubscribe))
  end

  it "renders the edit unsubscribe form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => unsubscribes_path(@unsubscribe), :method => "post" do
    end
  end
end
