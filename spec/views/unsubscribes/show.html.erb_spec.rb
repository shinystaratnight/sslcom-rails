require 'spec_helper'

describe "unsubscribes/show.html.erb" do
  before(:each) do
    @unsubscribe = assign(:unsubscribe, stub_model(Unsubscribe))
  end

  it "renders attributes in <p>" do
    render
  end
end
