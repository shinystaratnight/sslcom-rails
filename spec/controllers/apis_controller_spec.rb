require 'spec_helper'

describe ApisController do
  render_views

  it "responds to create_certificate_order" do
    post :create_certificate_order
    response.code.should eq("200")
  end

end
