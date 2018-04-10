# This class represent requests sent to the SSL.com CA. It's assumed the content-type is JSON

class SslcomCaRequest < CaApiRequest
  after_initialize do
    if new_record? and !self.response.blank?
      parsed=JSON.parse(self.response)
      self.username = parsed["username"] or parsed["user_name"]
      self.approval_id = parsed["approval_id"]
      self.certificate_chain = parsed["certificate_chain"]
    end
  end

  def x509_certificates
    OpenSSL::PKCS7.new(SignedCertificate.enclose_with_tags certificate_chain).certificates
  end

  def end_entity_certificate
    x509_certificates.first
  end
end