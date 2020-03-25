# frozen_string_literal: true

# == Schema Information
#
# Table name: api_credentials
#
#  id                           :integer          not null, primary key
#  account_key                  :string(255)
#  acme_acct_pub_key_thumbprint :string(255)
#  hmac_key                     :string(255)
#  roles                        :string(255)
#  secret_key                   :string(255)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  ssl_account_id               :integer
#
# Indexes
#
#  index_api_credentials_on_account_key_and_secret_key    (account_key,secret_key) UNIQUE
#  index_api_credentials_on_acme_acct_pub_key_thumbprint  (acme_acct_pub_key_thumbprint)
#  index_api_credentials_on_ssl_account_id                (ssl_account_id)
#

require 'rails_helper'

describe ApiCredential do
  subject { described_class.new }

  it { is_expected.to belong_to :ssl_account }
  it { is_expected.to have_db_column :account_key }
  it { is_expected.to have_db_column :acme_acct_pub_key_thumbprint }
  it { is_expected.to have_db_column :hmac_key }
  it { is_expected.to have_db_column :secret_key }
  it { is_expected.to have_db_column :roles }
  it { is_expected.to have_db_column :ssl_account_id }
end
