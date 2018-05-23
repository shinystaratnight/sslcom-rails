# This class represent requests sent to the SSL.com CA. It's assumed the content-type is JSON

class SslcomCaRequest < CaApiRequest
  after_initialize do
    if new_record? and !self.response.blank?
      parsed=JSON.parse(self.response)
      self.username = parsed["user_name"] || parsed["username"]
      self.approval_id = parsed["approval_id"]
      self.certificate_chain = parsed["certificate_chain"]
    end
  end

  scope :unexpired, ->{where{created_at > 48.hours.ago}}

  def x509_certificates
    OpenSSL::PKCS7.new(SignedCertificate.enclose_with_tags certificate_chain).certificates
  end

  def end_entity_certificate
    x509_certificates.first
  end

  def username
    read_attribute(:username) || ((JSON.parse(self.response)["user_name"] ||
        JSON.parse(self.response)["username"]) unless self.response.blank?)
  end

  def approval_id
    read_attribute(:approval_id) || (JSON.parse(self.response)["approval_id"] unless self.response.blank?)
  end

  def certificate_chain
    read_attribute(:certificate_chain) || (JSON.parse(self.response)["certificate_chain"] unless self.response.blank?)
  end
end