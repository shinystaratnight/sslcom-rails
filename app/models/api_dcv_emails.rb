class ApiDcvEmails < CaApiRequest
  validates :account_key, :secret_key, :domain_name, presence: true

  ACCESSORS = [:account_key, :secret_key, :domain_name]

  attr_accessor *ACCESSORS
  attr_accessor :email_addresses
end
