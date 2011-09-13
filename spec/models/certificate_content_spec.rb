require 'spec_helper'

describe CertificateContent, "as a ssl.com certificate order using FactoryGirl" do
  it "should have a csr when created" do
    @certificate_order = FactoryGirl.create(:new_dv_certificate_order)
    co = Factory(:certificate_content_w_csr, certificate_order: @certificate_order)
    co.csr.should_not be_blank
  end
end


