FactoryBot.define do
  factory :system_audit do
    association :owner, factory: :user
    association :target, factory: :certificate
  end
end
