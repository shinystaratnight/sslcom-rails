class Ca < ActiveRecord::Base

  has_and_belongs_to_many :certificates
  serialize :caa_issuers
  serialize :ekus

  # Root CAs - determines the certificate chain used
  CERTLOCK_CA = "certlock"
  ECOSSL_CA = "ecossl"
  SSLCOM_CA = "sslcom"
  MANAGEMENT_CA = "management_ca"

  END_ENTITY = {
    evcs: 'EV_CS_CERT_EE',
    cs: 'CS_CERT_EE',
    dvssl: 'DV_SERVER_CERT_EE',
    ovssl: 'OV_SERVER_CERT_EE',
    evssl: 'EV_SERVER_CERT_EE'
  }
  
  # issuer (entity and purpose)
  ISSUER = {sslcom_shadow: 1}
  
  validates :ref, presence: true, uniqueness: true
  
  private

  def set_profile_type
    self.profile_type = self.class.to_s
  end
end
