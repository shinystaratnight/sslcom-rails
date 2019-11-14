class ApiAcmeRequest < CaApiRequest
  attr_accessor :test, :action

  ACCOUNT_ACCESSORS = [:account_key, :secret_key, :debug]
  CREDENTIAL_ACCESSORS = [:hmac_key]

  attr_accessor *(
    ACCOUNT_ACCESSORS +
    CREDENTIAL_ACCESSORS
  ).uniq
end