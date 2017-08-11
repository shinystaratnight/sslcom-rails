FactoryGirl.define do
  factory :product_variant_group do
    variantable :uccssl
    title "Domains"
    status "live"
    description "Domain Names"
    text_only_description "Domain Names"
    serial nil
    published_as "live"
  end
end
