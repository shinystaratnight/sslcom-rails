require File.dirname(__FILE__) + '/../spec_helper'
#`rake db:test:clone_structure`

describe ApplicationController do
  fixtures :certificates, :sub_order_items, :product_variant_groups,
    :product_variant_items
  #setup up cookies
  before(:each) do
#    controller.stub!(:current_user_session).and_return(nil)
    controller.stub!(:current_user).and_return(nil)
    @cookies = { :cart =>
      '[{"pr":"high_assurance2tr","du":"1","li":"0","do":"0","af":1,"q":10}]' }
    controller.stub!(:cookies).and_return(@cookies)
  end

  it "should get certificate order from cart" do
    certs = controller.certificates_from_cookie
    certs.should have_exactly(1).item
    certs.each do |cert|
      cert.should be_a_kind_of CertificateOrder
      cert.quantity.should be(10)
      cert.certificate.should be_a_kind_of Certificate
    end
  end
end