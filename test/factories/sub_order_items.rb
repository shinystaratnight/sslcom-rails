FactoryGirl.define do
  factory :sub_order_item do
    product_variant_item
    quantity 3
    amount 17700
    product_id nil
  end
end
