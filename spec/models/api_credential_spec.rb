# frozen_string_literal: true
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
