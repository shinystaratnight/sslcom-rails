class Ca < ActiveRecord::Base
  # Root CAs
  CERTLOCK_CA = "certlock"
  SSLCOM_CA = "sslcom"
  MANAGEMENT_CA = "management_ca"

  # issuer (entity and purpose)
  ISSUER={sslcom_shadow: "ssl.com shadow"}

end
