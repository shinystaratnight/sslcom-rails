# frozen_string_literal: true
FactoryBot.define do
  factory :ssl_account do
    ssl_slug { 'team-' + Faker::Alphanumeric.alpha(number: 10) }
    billing_method { 'monthly' }
    workflow_state { 'active' }

    trait :billing_profile do
      after(:create) do |ssl|
        ssl.billing_profiles << create(:billing_profile)
      end
    end
  end
end
