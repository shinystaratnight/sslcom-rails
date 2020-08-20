class ApiSignedCertificateRequest < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :pub_key, presence: true
end
