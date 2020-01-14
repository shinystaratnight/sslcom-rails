# frozen_string_literal: true

FactoryBot.define do
  factory :ssl_account do
    # acct_number {}
    status {}
    ssl_slug {}
    company_name {}
    issue_dv_no_validation {}
    billing_method { 'monthly' }
    duo_enabled {}
    duo_own_used {}
    sec_type {}
    default_folder_id {}
    no_limit {}
    epki_agreement {}
    workflow_state { 'active' }
  end

  trait :billing_profile do
    after(:create) do |ssl|
      ssl.billing_profiles << create(:billing_profile)
    end
  end
end
