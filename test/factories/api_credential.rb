# frozen_string_literal: true

FactoryBot.define do
  factory :api_credential do
    account_key { Faker::Crypto.md5 }
    secret_key { Faker::Crypto.md5 }
    hmac_key { Faker::Crypto.sha256 }
    acme_acct_pub_key_thumbprint { 'bkNMcUF4R3I3LTl4QS1may03ODFzQVkxS1BqcXZtaXNpbzNHYzFwVE1ZSQ==' }
  end
end
