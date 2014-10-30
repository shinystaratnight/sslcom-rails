class CertUtil
  CONVERT_PKCS7=->(pem, pkcs7, chain){%x"openssl crl2pkcs7 -nocrl -certfile #{pem} -out #{pkcs7} -certfile #{chain}"}
  DECODE_CERTIFICATE=->(cert_file, format){%x"openssl #{format} -in #{cert_file} -text -noout #{'-print_certs' if format=='pkcs7'}"}

  def self.pem_to_pkcs7(pem, chain, out)
    CONVERT_PKCS7.call pem, out, chain
  end

  def self.decode_certificate(cert_file,format)
    DECODE_CERTIFICATE.call cert_file,format
  end
end
