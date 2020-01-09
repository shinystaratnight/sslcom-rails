# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  ssl_account_id      :integer
#  login               :string(255)      not null
#  email               :string(255)      not null
#  crypted_password    :string(255)
#  password_salt       :string(255)
#  persistence_token   :string(255)      not null
#  single_access_token :string(255)      not null
#  perishable_token    :string(255)      not null
#  status              :string(255)
#  login_count         :integer          default(0), not null
#  failed_login_count  :integer          default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  active              :boolean          default(FALSE), not null
#  openid_identifier   :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  first_name          :string(255)
#  last_name           :string(255)
#  phone               :string(255)
#  organization        :string(255)
#  address1            :string(255)
#  address2            :string(255)
#  address3            :string(255)
#  po_box              :string(255)
#  postal_code         :string(255)
#  city                :string(255)
#  state               :string(255)
#  country             :string(255)
#  is_auth_token       :boolean
#  default_ssl_account :integer
#  max_teams           :integer
#  main_ssl_account    :integer
#  persist_notice      :boolean          default(FALSE)
#  duo_enabled         :string(255)      default("enabled")
#

FactoryBot.define do
  factory :user do
    first_name            { Faker::Name.first_name }
    last_name             { Faker::Name.last_name }
    sequence(:login)      { Faker::Internet.username(specifier: 8..15) }
    sequence(:email)      { Faker::Internet.email }
    status                { 'enabled' }
    password              { 'Testing_ssl+1' }
    password_confirmation { 'Testing_ssl+1' }
    active                { true }

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
