class WhoisLookup < ApplicationRecord
  belongs_to  :csr
  before_create :query_whois

  WHOIS=->(domain){%x"whois #{domain}"}

  def self.registrant_whois(domain)
    whois = WHOIS.call(domain)
    refer = whois=~/refer:\s+?(\w)$/
  end

  def query_whois
    if csr.top_level_domain && Whois.find(csr.top_level_domain).try(:valid?)
      self.raw = whois = Whois.find(csr.top_level_domain)
      unless whois.blank?
        self.expiration = whois.expiration if whois.expiration_date_known?
        self.record_created_on = whois.creation_date if whois.creation_date_known?
        self.status = whois.status
      end
    end
  end

  def email_addresses
    self.raw.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/im).uniq unless
      self.raw.blank?
  end

  def self.email_addresses(raw)
    raw.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/im).uniq unless
        raw.blank?
  end

  def self.use_gem(fqdn)
    d=::PublicSuffix.parse(fqdn)
    Whois.whois(ActionDispatch::Http::URL.extract_domain(d.domain, 1)).inspect
  end
end
