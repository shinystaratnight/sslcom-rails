class Ca < ActiveRecord::Base

  has_many  :cas_certificates, dependent: :destroy
  has_many  :certificates, through: :cas_certificates
  serialize :caa_issuers
  serialize :ekus

  # Root CAs - determines the certificate chain used
  CERTLOCK_CA = "certlock"
  ECOSSL_CA = "ecossl"
  SSLCOM_CA = "sslcom"
  MANAGEMENT_CA = "management_ca"

  EKUS = {server: "tls",
          client: "client",
          email: "smime",
          time_stamping: "ts",
          code_signing: "cs"}

  END_ENTITY = {
          evcs:         'EV_CS_CERT_EE',
          cs:           'CS_CERT_EE',
          ov_client:    'OV_CLIENTAUTH_CERT_EE',
          dvssl:        'DV_SERVER_CERT_EE',
          ovssl:        'OV_SERVER_CERT_EE',
          evssl:        'EV_SERVER_CERT_EE'
  }
  
  # issuer (entity and purpose)
  ISSUER = {sslcom_shadow: 1}
  
  validates :ref, presence: true, uniqueness: true
  
  private

end
