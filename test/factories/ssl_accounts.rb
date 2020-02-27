# frozen_string_literal: true

# == Schema Information
#
# Table name: ssl_accounts
#
#  id                     :integer          not null, primary key
#  acct_number            :string(255)
#  billing_method         :string(255)      default("monthly")
#  company_name           :string(255)
#  duo_enabled            :boolean
#  duo_own_used           :boolean
#  epki_agreement         :datetime
#  issue_dv_no_validation :string(255)
#  no_limit               :boolean          default(FALSE)
#  roles                  :string(255)      default([])
#  sec_type               :string(255)
#  ssl_slug               :string(255)
#  status                 :string(255)
#  workflow_state         :string(255)      default("active")
#  created_at             :datetime
#  updated_at             :datetime
#  default_folder_id      :integer
#
# Indexes
#
#  index_ssl_account_on_acct_number                                 (acct_number)
#  index_ssl_accounts_an_cn_ss                                      (acct_number,company_name,ssl_slug)
#  index_ssl_accounts_on_acct_number_and_company_name_and_ssl_slug  (acct_number,company_name,ssl_slug)
#  index_ssl_accounts_on_default_folder_id                          (default_folder_id)
#  index_ssl_accounts_on_id_and_created_at                          (id,created_at)
#  index_ssl_accounts_on_ssl_slug_and_acct_number                   (ssl_slug,acct_number)
#

FactoryBot.define do
  factory :ssl_account do
    ssl_slug { "team-" + Faker::Alphanumeric.alpha(number: 10) }
    billing_method { 'monthly' }
    workflow_state { 'active' }
    after :create, &:create_api_credential

    trait :billing_profile do
      after(:create) do |ssl|
        ssl.billing_profiles << create(:billing_profile)
      end
    end
  end
end
