class CertUtil
  CONVERT_PKCS7=->(pem, pkcs7, chain){%x"openssl crl2pkcs7 -nocrl -certfile #{pem} -out #{pkcs7} -certfile #{chain}"}
  DECODE_CERTIFICATE=->(cert_file){%x"openssl x509 -in #{cert_file} -text -noout"}

  def self.pem_to_pkcs7(pem, chain, out)
    CONVERT_PKCS7.call pem, out, chain
  end

  def self.decode_certificate(cert_file)
    DECODE_CERTIFICATE.call cert_file
  end
end
