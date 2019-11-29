FactoryBot.define do
  factory :user  do
    first_name            {'first name'}
    last_name             {'last name'}
    sequence(:login)      {|n| "user_login#{n}"}
    sequence(:email)      {|n| "tester_#{n}@domain.com"}
    status                {'enabled'}
    password              {'Testing_ssl+1'}
    password_confirmation {'Testing_ssl+1'}
    active                {true}

    trait :sysadmin do
      after(:create) do |user|
        user.assignments << create(:assignment, :sysadmin)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :super_user do
      after(:create) do |user|
        user.assignments << create(:assignment, :super_user)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :owner do
      after(:create) do |user|
        user.assignments << create(:assignment, :owner)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :reseller do
      after(:create) do |user|
        user.assignments << create(:assignment, :reseller)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :account_admin do
      after(:create) do |user|
        user.assignments << create(:assignment, :account_admin)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :billing do
      after(:create) do |user|
        user.assignments << create(:assignment, :billing)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :installer do
      after(:create) do |user|
        user.assignments << create(:assignment, :installer)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :validations do
      after(:create) do |user|
        user.assignments << create(:assignment, :validations)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end

    trait :users_manager do
      after(:create) do |user|
        user.assignments << create(:assignment, :users_manager)
        user.ssl_accounts << user.assignments.first.ssl_account
        user.approved_teams << user.assignments.first.ssl_account
        user.default_ssl_account = user.assignments.first.ssl_account.id
      end
    end
  end
end
