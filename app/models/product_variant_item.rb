class ProductVariantItem < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false
  belongs_to  :product_variant_group
  has_one :sub_order_item
  acts_as_publishable :live, :draft, :discontinue_sell

  validates_uniqueness_of :display_order, :scope => :product_variant_group_id
  validates_presence_of :product_variant_group

  def certificate
    product_variant_group.variantable if
      product_variant_group &&
      product_variant_group.variantable &&
      product_variant_group.variantable.is_a?(Certificate)
  end

  def is_domain?
    item_type=='ucc_domain'
  end

  def is_duration?
    item_type=='duration'
  end

  def is_server_license?
    item_type=='server_license'
  end
end
