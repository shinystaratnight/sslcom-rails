class SubOrderItem < ApplicationRecord
  belongs_to  :sub_itemable, polymorphic: true
  belongs_to  :product_variant_item
  belongs_to  :product
  acts_as_sellable cents: :amount, currency: false
end
