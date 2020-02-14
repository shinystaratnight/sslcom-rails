# == Schema Information
#
# Table name: billing_profiles
#
#  id                         :integer          not null, primary key
#  address_1                  :string(255)
#  address_2                  :string(255)
#  card_number                :string(255)
#  city                       :string(255)
#  company                    :string(255)
#  country                    :string(255)
#  credit_card                :string(255)
#  data                       :binary(65535)
#  default_profile            :boolean
#  description                :string(255)
#  encrypted_card_number      :string(255)
#  encrypted_card_number_iv   :string(255)
#  encrypted_card_number_salt :string(255)
#  expiration_month           :integer
#  expiration_year            :integer
#  first_name                 :string(255)
#  last_digits                :string(255)
#  last_name                  :string(255)
#  notes                      :string(255)
#  phone                      :string(255)
#  postal_code                :string(255)
#  salt                       :binary(65535)
#  security_code              :string(255)
#  state                      :string(255)
#  status                     :string(255)
#  tax                        :string(255)
#  vat                        :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  ssl_account_id             :integer
#
# Indexes
#
#  index_billing_profile_on_ssl_account_id  (ssl_account_id)
#

class BillingProfileUnscoped < BillingProfile
  self.default_scopes = []
end
