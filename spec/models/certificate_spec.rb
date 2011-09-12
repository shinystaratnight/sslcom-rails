require 'spec_helper'

describe Certificate, "as a ssl.com dv certificate product" do
  it "should have a certificate chain" do
    cert = Certificate.where(product: "free").first
    cert.preferred_certificate_chain.should_not be_blank
  end
end


