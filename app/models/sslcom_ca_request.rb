# This class represent requests sent to the SSL.com CA. It's assumed the content-type is JSON

class SslcomCaRequest < CaApiRequest
  @parsed
  def username
    begin
      (@parsed ||= JSON.parse(response))["username"] unless response.blank?
    rescue
      @parsed=nil
    end
  end

  def approval_id
    begin
      (@parsed ||= JSON.parse(response))["approval_id"] unless response.blank?
    rescue
      @parsed=nil
    end
  end

  def certificate_chain
    begin
      (@parsed ||= JSON.parse(response))["certificate_chain"] unless response.blank?
    rescue
      @parsed=nil
    end
  end

  def x509_certificates
    OpenSSL::PKCS7.new(SignedCertificate.enclose_with_tags certificate_chain).certificates
  end

  def end_entity_certificate
    x509_certificates.first
  end
end