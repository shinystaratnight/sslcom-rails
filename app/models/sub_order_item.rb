class SubOrderItem < ActiveRecord::Base
  belongs_to  :sub_itemable, :polymorphic => true
  belongs_to  :product_variant_item
  acts_as_sellable :cents => :amount, :currency => false
end
