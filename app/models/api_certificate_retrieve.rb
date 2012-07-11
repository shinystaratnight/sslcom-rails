class ApiCertificateRetrieve < ApiCertificateRequest
  validates :account_key, :secret_key, :ref, :query_type, presence: true
end
