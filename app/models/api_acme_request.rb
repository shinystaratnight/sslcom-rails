class ApiAcmeRequest < CaApiRequest
  attr_accessor :test, :action

  ACCOUNT_ACCESSORS = [:account_key, :secret_key, :hmac, :debug]
  CREDENTIAL_ACCESSORS = [:hmac]

  attr_accessor *(
    ACCOUNT_ACCESSORS +
    CREDENTIAL_ACCESSORS
  ).uniq
end