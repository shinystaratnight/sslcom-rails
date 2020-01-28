# frozen_string_literal: true

# == Schema Information
#
# Table name: ssl_accounts
#
#  id                     :integer          not null, primary key
#  acct_number            :string(255)
#  roles                  :string(255)      default([])
#  created_at             :datetime
#  updated_at             :datetime
#  status                 :string(255)
#  ssl_slug               :string(255)
#  company_name           :string(255)
#  issue_dv_no_validation :string(255)
#  billing_method         :string(255)      default("monthly")
#  duo_enabled            :boolean
#  duo_own_used           :boolean
#  sec_type               :string(255)
#  default_folder_id      :integer
#  no_limit               :boolean          default(FALSE)
#  epki_agreement         :datetime
#  workflow_state         :string(255)      default("active")
#


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
