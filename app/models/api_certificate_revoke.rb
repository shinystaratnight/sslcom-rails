class ApiCertificateRevoke < ApiCertificateRequest
  validates :account_key, :secret_key, :reason, presence: true
  validates :ref, presence: true

end
