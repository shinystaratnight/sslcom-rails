class ApiAcmeRetrieve < ApiAcmeRequest
  validates :account_key, :secret_key, presence: true

  attr_accessor :hmac
end