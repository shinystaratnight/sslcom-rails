require 'spec_helper'

describe CertificateOrder, "as a ssl.com certificate order" do
  it "should be able to be created with a domain validated certificate" do
    co = Factory(:new_dv_certificate_order)
    co.sub_order_items.count.should == 1
    co.sub_order_items.should_not be_blank
    co.sub_order_items.last.product_variant_item.product_variant_group.variantable.product.should == "free"
    co.certificate.product.should =="free"
  end

  it "should have a registrant when created" do
    certificate_order = FactoryGirl.create(:new_dv_certificate_order,
      ssl_account: FactoryGirl.create(:ssl_account))
    certificate_content = FactoryGirl.create(:certificate_content_w_contacts,
      certificate_order: certificate_order)
    certificate_order.certificate_content.registrant.should_not be_blank
    certificate_order.certificate_content.registrant.company_name.should_not be_blank
  end
end


