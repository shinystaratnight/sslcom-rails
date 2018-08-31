require "declarative_authorization/maintenance"

class ApiManagedCertificateCreate < ApiSslManagerRequest
  validates :account_key, :secret_key, presence: true
  validates :certificates, presence: true

  def create_managed_certificates
    registered_agent = RegisteredAgent.find_by_ref(self.ref)

    self.certificates.each do |cert|
      managed_certificate = ManagedCertificate.new
      managed_certificate.body = cert
      managed_certificate.type = 'ManagedCertificate'
      managed_certificate.registered_agent = registered_agent
      managed_certificate.save!
    end

    registered_agent
  end
end