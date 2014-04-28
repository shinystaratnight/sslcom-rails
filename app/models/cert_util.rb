class CertUtil
  CONVERT_PKCS7=->(pem, pkcs7, chain){%x"openssl crl2pkcs7 -nocrl -certfile #{pem} -out #{pkcs7} -certfile #{chain}"}

  def self.pem_to_pkcs7(pem, chain, out)
    CONVERT_PKCS7.call pem, out, chain
  end
end
