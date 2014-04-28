require 'spec_helper'

describe SubOrderItem do
  it "has a valid factory" do
    expect(build :dv_sub_order_item).to be_valid
  end

  it "has a product variant item" do
    expect(create(:dv_sub_order_item).product_variant_item).to be_valid
  end

  it "has a certificate"do
    expect(create(:dv_sub_order_item).product_variant_item.certificate).to be_valid
  end
end
