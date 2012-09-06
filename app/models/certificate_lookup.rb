# This class looks up Web ssl certs on domains and provides
# a reference for expirations for both csrs and signed certificates

class CertificateLookup < ActiveRecord::Base
  has_many :site_checks
  has_many :csrs
  has_many :signed_certificates

  # scan all certs in the Web and update csrs and signed_certificates. Uniqueness
  # of installed certs on the Web will be determined by serial number
  def self.scan_certificates
    (Csr.pluck(:common_name)+SignedCertificate.pluck(:common_name)).uniq.find_each do |cn|
      sc=SiteCheck.new(cn)
      sc.create_certificate_lookup
      unless sc.certificate_lookup
        sc.certificate_lookup.update_references
      end
    end
  end

  # update references to all csrs and signed certs to this lookup
  def update_references
    Csr.find_all_by_common_name(common_name).each {|csr|
      csr.update_attribute(:certificate_lookup_id, id)}
    SignedCertificate.find_all_by_common_name(common_name).each {|sc|
      sc.update_attribute(:certificate_lookup_id, id)}
  end

end
