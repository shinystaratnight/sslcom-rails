require 'spec_helper'

describe ProductVariantGroup do
  it "has a valid factory" do
    expect(build :dv_product_variant_group).to be_valid
  end
end
