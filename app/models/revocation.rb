class Revocation < ActiveRecord::Base
  belongs_to :revoked_signed_certificates, class_name: "SignedCertificate", foreign_key: "revoked_signed_certificate_id"
  belongs_to :replacement_signed_certificates, class_name: "SignedCertificate", foreign_key: "replacement_signed_certificate_id"

  def revoked_signed_certificate
    if read_attribute(:revoked_signed_certificate_id).blank?
      sc=SignedCertificate.find_by_fingerprint(fingerprint)
      unless sc.blank?
        write_attribute(:revoked_signed_certificate_id, sc.id)
        save(validate: false)
        sc
      end
    else
      SignedCertificate.find(read_attribute(:revoked_signed_certificate_id))
    end
  end

  def replacement_signed_certificate
    if read_attribute(:replacement_signed_certificate_id).blank?
      sc=SignedCertificate.find_by_fingerprint(replacement_fingerprint)
      unless sc.blank?
        write_attribute(:replacement_signed_certificate_id, sc.id)
        save(validate: false)
        sc
      end
    else
      SignedCertificate.find(read_attribute(:replacement_signed_certificate_id))
    end
  end
end