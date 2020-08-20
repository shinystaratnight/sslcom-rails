# frozen_string_literal: true
FactoryBot.define do
  factory :sub_order_item do
    quantity { 1 }
    amount { 100 }

    association :product_variant_item, factory: :product_variant_item
  end
end
