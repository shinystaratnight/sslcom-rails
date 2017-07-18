FactoryGirl.define do
  factory :certificate_order do
    external_order_number '111111'
    ssl_account factory: [:ssl_account, :billing_profile]
    after(:build) do |co, evaluator|
      co.sub_order_items.build(product_variant_item:
         create(:certificate, :uccssl).product_variant_groups.first.product_variant_items.first)
    end
    after(:create) do |co, evaluator|
      co.certificate_contents << create(:certificate_content)
    end
  end
end
