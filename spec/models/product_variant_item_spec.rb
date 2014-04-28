require 'spec_helper'

describe ProductVariantItem do
  context "dv variant item" do
    it "has a valid factory" do
      expect(build :dv_product_variant_item).to be_valid
    end

    it "has a certificate" do
      expect(build(:dv_product_variant_item).certificate).to be_valid
    end
  end

end
