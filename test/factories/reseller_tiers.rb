# frozen_string_literal: true

# == Schema Information
#
# Table name: reseller_tiers
#
#  id           :integer          not null, primary key
#  label        :string(255)
#  description  :string(255)
#  amount       :integer
#  roles        :string(255)
#  published_as :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

FactoryBot.define do
  factory :reseller_tier do
    published_as { 'live' }
    label        { '1' }
    amount       { 0 }
    roles        { 'tier_1_reseller' }
    description  { { ideal_for: 'pay as you go' } }

    trait :professional do
      label        { '2' }
      amount       { 20_000 }
      roles        { 'tier_2_reseller' }
      description  { { ideal_for: 'professionals' } }
    end

    trait :west do
      label { 'west.com' }
      description { { name: 'west.com tier', ideal_for: 'pay as you go' } }
      published_as { 'live' }
    end

    trait :medium_business do
      label        { '3' }
      amount { 100_000 }
      roles        { 'tier_3_reseller' }
      description  { { ideal_for: 'small to medium sized businesses' } }
    end

    trait :large_business do
      label { '4' }
      amount { 500_000 }
      roles        { 'tier_4_reseller' }
      description  { { ideal_for: 'large businesses' } }
    end

    trait :enterprise do
      label { '5' }
      amount { 2_000_000 }
      roles        { 'tier_5_reseller' }
      description  { { ideal_for: 'enterprise organizations' } }
    end
  end
end
