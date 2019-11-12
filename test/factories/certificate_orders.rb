FactoryBot.define do
  factory :certificate_order do
    external_order_number {'111111'}
    ssl_account factory: [:ssl_account, :billing_profile]
    after(:build) do |co, evaluator|
      co.sub_order_items.build(product_variant_item:
         create(:certificate, :uccssl).cached_product_variant_items.first)
    end
    after(:create) do |co, evaluator|
      co.certificate_contents.create(csr: @nonwildcard_csr, certificate_order: co)
    end
  end
end
