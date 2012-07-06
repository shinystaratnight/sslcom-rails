require 'spec_helper'

describe ApisController do
  #render_views

  it "responds to create_certificate_order" do
    post :create_certificate_order_v1_0
    response.code.should eq("200")
  end

  it "requires certain parameters for dv certs" do
    post :create_certificate_order_v1_0, api_certificate_request: {ca: "p100", secret_key: "cv"}, format: :json
    response.body.should eq("200")
  end

  it "returns an order number when successfully submitted" do
    post :create_certificate_order_v1_0, api_certificate_request: {ca: "p100", secret_key: "cv"}, format: :json
    response.body.should eq("200")
  end

end
