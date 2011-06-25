require 'spec_helper'

describe "surls/show.html.erb" do
  before(:each) do
    @surl = assign(:surl, stub_model(Surl))
  end

  it "renders attributes in <p>" do
    render
  end
end
