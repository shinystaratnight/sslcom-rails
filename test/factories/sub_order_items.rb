# frozen_string_literal: true

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

FactoryBot.define do
  factory :sub_order_item do
    quantity { 1 }
    amount { 100 }

    association :product_variant_item, factory: :product_variant_item
  end
end
