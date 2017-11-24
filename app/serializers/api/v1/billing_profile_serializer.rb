class Api::V1:: BillingProfileSerializer < Api::V1::BaseSerializer
  attribute :first_name
  attribute :last_name
  attribute :credit_card
  attribute :last_digits
  attribute :expiration_year
  attribute :expiration_month
end
