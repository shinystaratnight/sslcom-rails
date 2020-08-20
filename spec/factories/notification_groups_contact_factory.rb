FactoryBot.define do
  factory :notification_groups_contact do
    sequence(:email_address) { |n| "test_user#{n}@gmail.com" }
  end
end
