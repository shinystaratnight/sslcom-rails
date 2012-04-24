require 'spec_helper'

describe ApisController do
  render_views

  it "responds to create_certificate_order" do
    post :create_certificate_order_v1_0
    response.code.should eq("200")
  end

  it "requires certain parameters for dv certs" do
    post :create_certificate_order_v1_0, produce_code: "p100"
    response.body.should eq("200")
  end
end
