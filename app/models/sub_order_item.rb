# Represents smaller 'buyable' sub units to a main order. Basically a buyable version of ProductVariantItem that can be
# linked to an Order and CertificateOrder
# ie duration and domains are sub units of a certificate order

class SubOrderItem < ActiveRecord::Base
  belongs_to  :sub_itemable, :polymorphic => true
  belongs_to  :product_variant_item
  acts_as_sellable :cents => :amount, :currency => false
end
