# frozen_string_literal: true

class ApiAcmeRequest < CaApiRequest
  attr_accessor :test, :action

  ACCOUNT_ACCESSORS = %i[account_key secret_key debug].freeze
  CREDENTIAL_ACCESSORS = %i[hmac_key certificate_order_id].freeze

  attr_accessor *(ACCOUNT_ACCESSORS + CREDENTIAL_ACCESSORS).uniq
end
