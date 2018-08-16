class WhoisLookup < ActiveRecord::Base
  belongs_to  :csr
  before_create :query_whois
  
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
    self.raw.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/im).uniq unless
      self.raw.blank?
  end
end
