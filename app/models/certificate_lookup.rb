class CertificateLookup < ApplicationRecord
  has_many :site_checks
  has_many :csrs
  has_many :signed_certificates

  scope :most_recent_expiring, lambda{|start, finish|
    find_by_sql("select * from certificate_lookups as c where expires_at between '#{start}' AND '#{finish}' AND created_at = ( select max(created_at) from certificate_lookups where common_name like c.common_name )")}

  # scan all certs in the Web and update csrs and signed_certificates. Uniqueness
  # of installed certs on the Web will be determined by serial number
  def self.scan_certificates(cutoff_date=Date.today)
    (Csr.pluck(:common_name)+SignedCertificate.pluck(:common_name)).uniq.each do |cn|
      c=CertificateLookup.find_by_common_name(cn.gsub("*.", "www."))
      if c.blank? || c.created_at < cutoff_date
        sc=SiteCheck.new(url: cn, verify_trust: false)
        if sc.create_certificate_lookup
          sc.certificate_lookup.update_references(cn)
        end
      end
    end
  end

  # update references to all csrs and signed certs to this lookup
  def update_references(cn=self.common_name)
    Csr.find_all_by_common_name(cn).each {|csr|
      csr.update_attribute(:certificate_lookup_id, id)}
    SignedCertificate.find_all_by_common_name(cn).each {|sc|
      sc.update_attribute(:certificate_lookup_id, id)}
  end

  def lookup
    SiteCheck.new url: common_name, verify_trust: false
  end
end
