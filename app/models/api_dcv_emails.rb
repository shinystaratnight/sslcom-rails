class ApiDcvEmails < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :domain_name, domain_name: true

  attr_accessor :email_addresses
end
