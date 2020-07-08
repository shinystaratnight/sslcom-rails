# == Schema Information
#
# Table name: funded_accounts
#
#  id             :integer          not null, primary key
#  card_declined  :text(65535)
#  cents          :integer          default("0")
#  currency       :string(255)
#  state          :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  ssl_account_id :integer
#
# Indexes
#
#  index_funded_accounts_on_ssl_account_id  (ssl_account_id)
#

FactoryBot.define do
  factory :funded_account do
    card_declined     { 'false' }
    cents             { 10_000 }
    currency          { 'USD' }
    ssl_account
  end

  trait :declined_funded_account do
    card_declined      { 'true' }
  end
end
