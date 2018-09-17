class Ca < ActiveRecord::Base

  has_many  :cas_certificates, dependent: :destroy
  has_many  :certificates, through: :cas_certificates
  serialize :caa_issuers
  serialize :ekus

  scope :ssl_account, ->(ssl_account){where{cas_certificates.ssl_account_id==ssl_account.id}.uniq} #private PKI
  scope :ssl_account_or_general_default, ->(ssl_account){
    (ssl_account(ssl_account).empty? ? general : ssl_account(ssl_account)).default}
  scope :general, ->{where{cas_certificates.ssl_account_id==nil}} # Cas not assigned to any team (Public PKI)
  scope :default, ->{where{cas_certificates.status==CasCertificate::STATUS[:default]}.uniq}
  scope :shadow,  ->{where{cas_certificates.status==CasCertificate::STATUS[:shadow]}.uniq}

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
