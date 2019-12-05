FactoryBot.define do
  factory :assignment do
    ssl_account
    role
    user

    trait :sysadmin do
      after(:create) do |assignment|
        assignment.role = create(:role, :sysadmin)
      end
    end

    trait :super_user do
      after(:create) do |assignment|
        assignment.role = create(:role, :super_user)
      end
    end

    trait :owner do
      after(:create) do |assignment|
        assignment.role = create(:role, :owner)
      end
    end

    trait :reseller do
      after(:create) do |assignment|
        assignment.role = create(:role, :reseller)
      end
    end

    trait :account_admin do
      after(:create) do |assignment|
        assignment.role = create(:role, :account_admin)
      end
    end

    trait :billing do
      after(:create) do |assignment|
        assignment.role = create(:role, :billing)
      end
    end

    trait :installer do
      after(:create) do |assignment|
        assignment.role = create(:role, :installer)
      end
    end

    trait :validations do
      after(:create) do |assignment|
        assignment.role = create(:role, :validations)
      end
    end

    trait :users_manager do
      after(:create) do |assignment|
        assignment.role = create(:role, :users_manager)
      end
    end
  end
end
