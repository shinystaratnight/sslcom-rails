# This class represent requests sent to the SSL.com CA. It's assumed the content-type is JSON

class SslcomCaRequest < CaApiRequest
  after_initialize do
    if new_record? and !self.response.blank?
      parsed=JSON.parse(self.response)
      self.username = parsed["user_name"] || parsed["username"]
      self.approval_id = parsed["approval_id"]
      self.certificate_chain = parsed["certificate_chain"]
      if self.username.blank? and !self.parameters.blank?
        parsed_req=JSON.parse(self.parameters)
        self.username = parsed_req["user_name"] || parsed_req["username"]
      end
    end
  end

  scope :unexpired, ->{where{created_at > 48.hours.ago}}

  def pkcs7
    certs=OpenSSL::PKCS7.new(SignedCertificate.enclose_with_tags(certificate_chain))
    add_this=Certificate.xcert_certum(certs.certificates.last,true)
    certs.certificates=certs.certificates[0..-2]+[OpenSSL::X509::Certificate.new(add_this)]
    certs
  end

  def x509_certificates
    pkcs7.certificates
  end

  def end_entity_certificate
    x509_certificates.first
  end

  def username
    read_attribute(:username) || ((JSON.parse(self.response)["user_name"] ||
        JSON.parse(self.response)["username"]) unless self.response.blank?)
  end

  def request_username
    (JSON.parse(self.parameters)["user_name"] || JSON.parse(self.response)["username"]) unless self.parameters.blank?
  end

  def approval_id
    read_attribute(:approval_id) || (JSON.parse(self.response)["approval_id"] unless self.response.blank?)
  end

  def certificate_chain
    read_attribute(:certificate_chain) || (JSON.parse(self.response)["certificate_chain"] unless self.response.blank?)
  end

  def call_again
    SslcomCaApi.call_ca(request_url,{},parameters)
  end
end