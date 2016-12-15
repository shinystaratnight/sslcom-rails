FactoryGirl.define do
  factory :ssl_account do
  end

  trait :billing_profile do
    after(:create) do |ssl|
      ssl.billing_profiles << create(:billing_profile)
    end
  end
end
