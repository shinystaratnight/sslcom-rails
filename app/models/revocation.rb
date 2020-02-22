# == Schema Information
#
# Table name: revocations
#
#  id                                :integer          not null, primary key
#  fingerprint                       :string(255)
#  message_after_revoked             :text(65535)
#  message_before_revoked            :text(65535)
#  replacement_fingerprint           :string(255)
#  revoked_on                        :datetime
#  status                            :string(255)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  replacement_signed_certificate_id :integer
#  revoked_signed_certificate_id     :integer
#
# Indexes
#
#  index_revocations_on_fingerprint                        (fingerprint)
#  index_revocations_on_replacement_fingerprint            (replacement_fingerprint)
#  index_revocations_on_replacement_signed_certificate_id  (replacement_signed_certificate_id)
#  index_revocations_on_revoked_signed_certificate_id      (revoked_signed_certificate_id)
#

class Revocation < ApplicationRecord
  belongs_to :revoked_signed_certificate, class_name: "SignedCertificate", foreign_key: "revoked_signed_certificate_id"
  belongs_to :replacement_signed_certificate, class_name: "SignedCertificate", foreign_key: "replacement_signed_certificate_id"

  def revoked_signed_certificate
    if read_attribute(:revoked_signed_certificate_id).blank?
      return nil if fingerprint.blank?
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
      return nil if replacement_fingerprint.blank?
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

  def self.load_revocations(file_name)
    File.open(file_name, "r").each_line do |line|
      data=line.split(",")
      revocation=Revocation.find_or_initialize_by(fingerprint: data[0].downcase)
      next if revocation.status=="replacement_issued" or (revocation.status.blank? and !revocation.new_record?)
      attr={}
      sc=SignedCertificate.find_by_fingerprint(data[0].downcase)
      if sc and sc.csr.certificate_content
        attr.merge!({revoked_signed_certificate_id: sc.id, status: "revoke_cert_found"})
        replacement_cert=revocation.replacement_signed_certificate ||
            sc.csr.get_ejbca_certificate(data[1].gsub(/\n\z/,''))
        if replacement_cert
          attr.merge!({replacement_fingerprint: replacement_cert.fingerprint.downcase,
                       replacement_signed_certificate_id: replacement_cert.id,
                       status: "replacement_issued"})
        end
      end
      Revocation.find_or_initialize_by(fingerprint: data[0].downcase).update_attributes(attr)
    end
  end
end
