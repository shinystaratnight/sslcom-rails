# frozen_string_literal: true

FactoryBot.define do
  factory :product_variant_group do
    variantable { nil }
    title { 'Domains' }
    status { 'live' }
    description { 'Domain Names' }
    text_only_description { 'Domain Names' }
    serial { nil }
    published_as { 'live' }
  end
end
