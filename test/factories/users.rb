FactoryGirl.define do
  factory :user  do
    first_name            'first name'
    last_name             'last name'
    sequence(:login)      {|n| "user_login#{n}"}
    sequence(:email)      {|n| "tester_#{n}@domain.com"}
    status                'enabled'
    password              'Testing_ssl'
    password_confirmation 'Testing_ssl'
    active                true

    trait :sysadmin do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::SYS_ADMIN)])}
    end

    trait :super_user do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::SUPER_USER)])}
    end

    trait :account_admin do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::ACCOUNT_ADMIN)])}
    end

    trait :reseller do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::RESELLER)])}
    end

    trait :ssl_user do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::SSL_USER)])}
    end

    trait :vetter do
      after(:create) {|u| u.create_ssl_account([Role.get_role_id(Role::VETTER)])}
    end
  end
end
