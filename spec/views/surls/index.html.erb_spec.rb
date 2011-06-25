require 'spec_helper'

describe "surls/index.html.erb" do
  before(:each) do
    assign(:surls, [
      stub_model(Surl),
      stub_model(Surl)
    ])
  end

  it "renders a list of surls" do
    render
  end
end
