class ApiAcmeRequest < CaApiRequest
  attr_accessor :test, :action

  ACCOUNT_ACCESSORS = %i[account_key secret_key debug acme_acct_pub_key_thumbprint].freeze
  CREDENTIAL_ACCESSORS = %i[hmac_key certificate_order_ref acme_acct_pub_key_thumbprint].freeze

  attr_accessor *(ACCOUNT_ACCESSORS + CREDENTIAL_ACCESSORS).uniq
end
