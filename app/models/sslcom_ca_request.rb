# This class represent requests sent to the SSL.com CA. It's assumed the content-type is JSON

class SslcomCaRequest < CaApiRequest
  @parsed
  def user_name
    (@parsed || JSON.parse(response))["user_name"]
  end

  def certificate_chain
    (@parsed || JSON.parse(response))["certificate_chain"]
  end

  def x509_certificates
    OpenSSL::PKCS7.new(SignedCertificate.enclose_with_tags certificate_chain).certificates
  end
end