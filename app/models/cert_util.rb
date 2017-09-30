class CertUtil
  CONVERT_PKCS7_TO_PEM=->(pem, pkcs7){%x"openssl pkcs7 -print_certs -in #{pkcs7} -out #{pem}"}
  CONVERT_PEM_TO_PKCS7=->(pem, pkcs7, chain){%x"openssl crl2pkcs7 -nocrl -certfile #{pem} -out #{pkcs7} -certfile #{chain}"}
  DECODE_CERTIFICATE=->(cert_file, format){%x"openssl #{format} -in #{cert_file} -text -noout #{'-print_certs' if format=='pkcs7'}"}
  CONNECT_HTTPS=->(host, port="443", protocol="tls1_2"){%x"openssl s_client -connect #{host}:#{port} -#{protocol}"}

  def self.pkcs7_to_pem(pem, out)
    CONVERT_PKCS7_TO_PEM.call pem, out
  end

  def self.pem_to_pkcs7(pem, chain, out)
    CONVERT_PEM_TO_PKCS7.call pem, out, chain
  end

  def self.decode_certificate(cert_file,format)
    DECODE_CERTIFICATE.call cert_file,format
  end


  # openssl pkcs7 -in orig_pkcs7.cer -out all_x509.pem -print_certs (where
  # orig_pkcs7.cer is your original pkcs7 cert and all_x509.pem are all the
  # resulting x509 certs)
  #
  # to convert a pkcs7 to it's x509 components, and then converting those
  # x509 certs back into a pkcs7 file using:
  #
  # openssl crl2pkcs7 -nocrl -certfile certificate.cer -out new_pkcs7.cer
  # -certfile x509_chain.pem (where new_pkcs7.cer is the new pkcs7 cert which
  # should match the original you sent us, x509_chain.pem are the intermediate
  # certs copied from all_x509.pem and certificate.cer is the certificate file
  # copied from all_x509.pem)
end
