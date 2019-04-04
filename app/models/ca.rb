class Ca < ActiveRecord::Base

  has_many  :cas_certificates, dependent: :destroy
  has_many  :certificates, through: :cas_certificates
  serialize :caa_issuers
  serialize :ekus

  scope :ssl_account, ->(ssl_account){joins{cas_certificates}.where{cas_certificates.ssl_account_id==ssl_account.id}.uniq} #private PKI
  scope :ssl_account_or_general, ->(ssl_account){
    (ssl_account(ssl_account).empty? ? general : ssl_account(ssl_account))}
  scope :ssl_account_or_general_default, ->(ssl_account){
    ssl_account_or_general(ssl_account).default}
  scope :ssl_account_or_general_shadow, ->(ssl_account){
    ssl_account_or_general(ssl_account).shadow}
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
  SSL_ACCOUNT_MAPPING = {"a30-1e3mjj3" =>
                          {"SSLcom-SubCA-SSL-RSA-4096-R1" => "DTNT-Intermediate-SSL-RSA-4096-R2",
                          "SSLcom-SubCA-CodeSigning-RSA-4096-R1" => "DTNT-Intermediate-codeSigning-RSA-4096-R2",
                          "SSLcom-SubCA-EV-SSL-RSA-4096-R3" => "DTNT-Intermediate-EV-SSL-RSA-4096-R2"},
                        "ade-1e41it0" =>
                          {"SSLcom-SubCA-SSL-RSA-4096-R1" => "MilleniumSign-Intermediate-SSL-RSA-4096-R2",
                          "SSLcom-SubCA-SSL-ECC-384-R1" => "MilleniumSign-Intermediate-SSL-ECC-384-R2",
                          "SSLcom-SubCA-CodeSigning-RSA-4096-R1" => "MilleniumSign-Intermediate-codeSigning-RSA-4096-R3",
                          "SSLcom-SubCA-clientCert-RSA-4096-R2" => "MilleniumSign-Intermediate-clientCert-RSA-4096-R3",
                          "SSLcom-SubCA-clientCert-ECC-384-R2" => "MilleniumSign-Intermediate-clientCert-ECC-384-R3",
                          "SSLcom-SubCA-EV-SSL-RSA-4096-R3" => "MilleniumSign-Intermediate-EV-SSL-RSA-4096-R3"}}

  validates :ref, presence: true, uniqueness: true

  def ecc_profile
    Ca.find_by(end_entity: end_entity, description: description, algorithm: "ecc" )
  end

  def downstep
    down_profile,down_entity=
        case profile_name
        when /\AEV/
          [profile_name,end_entity].map{|field|field.gsub "EV","DV"}
        when /\AOV/
          [profile_name,end_entity].map{|field|field.gsub "OV","DV"}
        end
    Ca.find_by(profile_name: down_profile, host: host, end_entity: down_entity)
  end

  private

end
