class ApiCertificateRevoke < ApiCertificateRequest
  validates :account_key, :secret_key, :reason, presence: true
  validates :ref, presence: true

  # return values
  attr_accessor :status

end
