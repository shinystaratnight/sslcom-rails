require "declarative_authorization/maintenance"

class ApiSslManagerRetrieve < ApiSslManagerRequest
  validates :account_key, :secret_key, presence: true
end
