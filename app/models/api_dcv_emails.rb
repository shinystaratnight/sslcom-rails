class ApiDcvEmails < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :domains, domain_name: true, unless: "domain_names.blank?"
  validates :domain, domain_name: true, unless: "domain_name.blank?"
  validates :domain, presence: true, if: "domain_names.blank?"

  attr_accessor :email_addresses

end
