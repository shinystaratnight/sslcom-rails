# == Schema Information
#
# Table name: sub_order_items
#
#  id                      :integer          not null, primary key
#  amount                  :integer
#  quantity                :integer
#  sub_itemable_type       :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  product_id              :integer
#  product_variant_item_id :integer
#  sub_itemable_id         :integer
#
# Indexes
#
#  index_sub_order_items_on_product_id                             (product_id)
#  index_sub_order_items_on_product_variant_item_id                (product_variant_item_id)
#  index_sub_order_items_on_sub_itemable                           (id,sub_itemable_id,sub_itemable_type)
#  index_sub_order_items_on_sub_itemable_id_and_sub_itemable_type  (sub_itemable_id,sub_itemable_type)
#

# Represents smaller 'buyable' sub units to a main order. Basically a buyable version of ProductVariantItem that can be
# linked to an Order and CertificateOrder
# ie duration and domains are sub units of a certificate order

class SubOrderItem < ApplicationRecord
  belongs_to  :sub_itemable, polymorphic: true
  belongs_to  :product_variant_item
  belongs_to  :product
  acts_as_sellable cents: :amount, currency: false
end
