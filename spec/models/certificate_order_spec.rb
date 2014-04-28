require 'spec_helper'

describe CertificateOrder, "as a ssl.com certificate order using FactoryGirl" do

  context "new domain validated" do
    it "has a valid sub_order_item" do
      expect(create(:new_dv_certificate_order).sub_order_items.count).to eq(1)
    end

    it "has a valid factory" do
      expect(build :new_dv_certificate_order).to be_valid
    end
  end

  it "should be able to create a new order with a domain validated certificate" do
    expect { @co=create(:new_dv_certificate_order) }.to change(CertificateOrder, :count).by(1)
    @co=create(:new_dv_certificate_order)
    @co.should be_new
    @co.sub_order_items.count.should == 1
    @co.sub_order_items.should_not be_blank
    @co.sub_order_items.last.product_variant_item.product_variant_group.variantable.product.should == "free"
    @co.certificate.product.should =="free"
    @co.ref.should_not be_blank
    @co.preferred_certificate_chain.should_not be_blank
  end

  it "should be able to create a completed order with a domain validated certificate" do
    expect { @co=Factory(:completed_unvalidated_dv_certificate_order) }.to change(CertificateOrder, :count).by(1)
    @co.should be_paid
    @co.sub_order_items.count.should == 1
    @co.sub_order_items.should_not be_blank
    @co.sub_order_items.last.product_variant_item.product_variant_group.variantable.product.should == "free"
    @co.certificate.product.should =="free"
    @co.ref.should_not be_blank
    @co.should_not be_new_record
    @co.preferred_certificate_chain.should_not be_blank
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


