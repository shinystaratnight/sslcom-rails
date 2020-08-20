require "declarative_authorization/maintenance"

class ApiManagedCertificateCreate < ApiSslManagerRequest
  attr_accessor :status

  validates :account_key, :secret_key, presence: true
  validates :certificates, presence: true

  def create_managed_certificates
    registered_agent = RegisteredAgent.find_by_ref(self.ref)

    self.certificates.each do |cert|
      managed_certificate = ManagedCertificate.new
      managed_certificate.body = cert
      managed_certificate.type = 'ManagedCertificate'
      managed_certificate.registered_agent = registered_agent
      managed_certificate.status = managed_certificate.expired? ? "expired" : "valid"
      managed_certificate.save!
    end

    registered_agent.api_status = 'registered'
    registered_agent
  end
end
