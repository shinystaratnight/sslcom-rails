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

  it "returns an order number when successfully submitted a request for ev" do
    params = {account_key: "something",
              secret_key:"something",
              product: "100",
              period: "365",
              server_count: "1",
              server_software: "15",
              csr: @lobby_sb_betsoftgaming_com_csr,
              organization_name: "betsoftgaming",
              street_address_1: "somewhere st",
              locality_name: "new york",
              state_or_province_name: "new york",
              postal_code: "77777",
              country_name: "US",
              duns_number: "1234567",
              company_number: "bet soft gaming inc",
              registered_country_name: "US",
              incorporation_date: "12/12/2000",
              is_customer_validated: "y"}
    post :create_certificate_order_v1_0, api_certificate_request: params, format: :json
    response.body.should eq("200")
  end

end
