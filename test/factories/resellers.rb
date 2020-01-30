# frozen_string_literal: true

FactoryBot.define do
  factory :reseller do
    published_as { 'live' }
    label        { '1' }
    amount       { 0 }
    roles        { 'tier_1_reseller' }
    description  { { ideal_for: 'pay as you go' } }
  end
end
