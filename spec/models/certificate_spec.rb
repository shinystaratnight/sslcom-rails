require 'spec_helper'

describe Certificate, "as a ssl.com dv certificate product" do
  it "should have a certificate chain" do
    expect(create(:dv_certificate).preferred_certificate_chain).to be
    # cert = Certificate.where(product: "free").first
    # cert.preferred_certificate_chain.should_not be_blank
  end
end


