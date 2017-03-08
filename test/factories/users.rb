FactoryGirl.define do
  factory :user  do
    first_name            'first name'
    last_name             'last name'
    sequence(:login)      {|n| "user_login#{n}"}
    sequence(:email)      {|n| "tester_#{n}@domain.com"}
    status                'enabled'
    password              'Testing_ssl+1'
    password_confirmation 'Testing_ssl+1'
    active                true

    trait :sysadmin do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::SYS_ADMIN)])}
    end

    trait :super_user do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::SUPER_USER)])}
    end

    trait :owner do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::OWNER)])}
    end

    trait :reseller do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::RESELLER)])}
    end

    trait :account_admin do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::ACCOUNT_ADMIN)])}
    end

    trait :billing do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::BILLING)])}
    end

    trait :installer do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::INSTALLER)])}
    end

    trait :validations do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::VALIDATIONS)])}
    end

    trait :users_manager do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::USERS_MANAGER)])}
    end
  end
end