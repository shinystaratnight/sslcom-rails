# frozen_string_literal: true

FactoryBot.define do
  factory :certificate_order do
    workflow_state { 'paid' }
    ref { 'co-ee1eufn55' }
    amount { '11000' }
    ca { 'SSLcomSHA2' }
    ssl_account
  end
end
