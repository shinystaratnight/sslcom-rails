# frozen_string_literal: true

FactoryBot.define do
  factory :product_variant_group do
    title { 'Domains' }
    status { 'live' }
    description { 'Domain Names' }
    text_only_description { 'Domain Names' }
    serial { nil }
    published_as { 'live' }

    association :variantable, factory: %i[certificate evuccssl]
  end
end
