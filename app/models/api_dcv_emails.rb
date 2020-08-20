class ApiDcvEmails < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :domains, domain_name: true, unless: -> { domains.blank? }
  validates :domain, domain_name: true, unless: -> { domain.blank? }
  validates :domain, presence: true, if: -> { domains.blank? }

  attr_accessor :email_addresses
end
