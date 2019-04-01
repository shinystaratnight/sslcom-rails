class RevocationNotification < ActiveRecord::Base
  serialize :fingerprints

  def self.load_revocations
    # get hash of {email: [to_be_revoked_signed_certificates, replacement_signed_certificates]}
    notifications={}
    Revocation.find_each do |revocation|
      sc=SignedCertificate.find_by_fingerprint(revocation.fingerprint.downcase)
      next if sc.blank?
      cc=sc.certificate_content
      next if cc.blank?
      cc.emergency_contact_emails.each {|email|
        fingerprint=[revocation.fingerprint,revocation.replacement_fingerprint]
        notifications[email] ||= RevocationNotification.find_or_initialize_by(email: email)
        notifications[email].fingerprints ||= []
        notifications[email].status ||= "loaded"
        notifications[email].fingerprints << fingerprint unless notifications[email].fingerprints.include?(fingerprint)
        notifications[email].save
      }
      # get all account admin contacts and certificate_order contacts into the hash
    end
  end
end