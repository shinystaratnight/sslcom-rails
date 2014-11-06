module SignedCertificateHelper
  def certificate_formats(certificate_content)
    csr, sc = certificate_content.csr, certificate_content.csr.signed_certificate
    pkcs7_csr_signed_certificate_url(csr, sc)
  end
end
