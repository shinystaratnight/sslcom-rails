require "declarative_authorization/maintenance"

class ApiManagedCertificateRetrieve < ApiSslManagerRequest
  validates :account_key, :secret_key, presence: true
end
