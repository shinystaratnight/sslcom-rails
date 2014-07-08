class ApiDcvEmails < ApiCertificateRequest
  validates :account_key, :secret_key, presence: true
  validates :domain_names, domain_name: true, unless: "domain_names.blank?"
  validates :domain_name, domain_name: true, unless: "domain_name.blank?"
  validates :domain_name, presence: true, if: "domain_names.blank?"

  attr_accessor :email_addresses

end
