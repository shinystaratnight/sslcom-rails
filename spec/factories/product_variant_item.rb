# frozen_string_literal: true

FactoryBot.define do
  factory :product_variant_item do
    title { '1 Year Domain For 3 Domains (ea domain)' }
    status { 'live' }
    description { '1 year domain for 3 domains (ea domain)' }
    text_only_description { '1 year domain for 3 domains (ea domain)' }
    amount { 5900 }
    item_type { 'ucc_domain' }
    value { '365' }
    serial { 'sslcomucc256ssl1yrdm' }
    published_as { 'live' }

    product_variant_group
  end
end
