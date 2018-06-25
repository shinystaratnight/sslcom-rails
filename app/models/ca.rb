class Ca < ActiveRecord::Base
  has_and_belongs_to_many :certificates
  serialize :caa_issuers

  # Root CAs - determines the certificate chain used
  CERTLOCK_CA = "certlock"
  SSLCOM_CA = "sslcom"
  MANAGEMENT_CA = "management_ca"

  # issuer (entity and purpose)
  ISSUER={sslcom_shadow: 1}

end
