require 'spec_helper'

describe Certificate, "as a ssl.com dv certificate product" do
  it "should have a certificate chain" do
    expect(create(:dv_certificate).preferred_certificate_chain).to be
    # cert = Certificate.where(product: "free").first
    # cert.preferred_certificate_chain.should_not be_blank
  end

  context "365 day Basic SSL" do
    it "has a product_variant_item" do
      expect(create(:basic_ssl).items_by_duration.count).to eq(1)
    end

    it "has product_variant_groups" do
      expect(create(:basic_ssl).product_variant_groups.count).to be > 0
    end

    it "has product_variant_items" do
      expect(create(:basic_ssl).product_variant_items.count).to be > 0
    end
  end
end


