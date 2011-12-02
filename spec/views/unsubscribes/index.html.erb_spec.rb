require 'spec_helper'

describe "unsubscribes/index.html.erb" do
  before(:each) do
    assign(:unsubscribes, [
      stub_model(Unsubscribe),
      stub_model(Unsubscribe)
    ])
  end

  it "renders a list of unsubscribes" do
    render
  end
end
