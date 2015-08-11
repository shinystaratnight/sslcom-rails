class ApiParameters < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :api_call, presence: true

  attr_accessor :parameters

end
