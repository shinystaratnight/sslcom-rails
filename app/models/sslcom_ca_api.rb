require 'net/http'
require 'net/https'
require 'open-uri'

class SslcomCaApi

  # DV_ECC_SERVER_CERT is linked to the
  # CertLockECCSSLsubCA
  # SSLcom-SubCA-SSL-ECC-384-R1
  # ManagementCA

  DEV_HOST = "http://192.168.100.5:8080/restapi"

  CERTLOCK_CA = "certlock"

  SIGNATURE_HASH = %w(NO_PREFERENCE INFER_FROM_CSR PREFER_SHA2 PREFER_SHA1 REQUIRE_SHA2)
  APPLY_SSL_URL=DEV_HOST+"/v1/certificate/pkcs10"
  REVOKE_SSL_URL=DEV_HOST+"/v1/certificate/revoke"
  RESPONSE_TYPE={"zip"=>0,"netscape"=>1, "pkcs7"=>2, "individually"=>3}
  RESPONSE_ENCODING={"base64"=>0,"binary"=>1}

  # using the csr, determine the algorithm used
  def self.sig_alg_parameter(csr)
    case csr.sig_alg
      when /rsa/i
        "RSA"
      when /ecdsa/i
        "ECC"
      when /dsa/i
        "DSA"
    end
  end

  # end entity profile details what will be in the certificate
  def self.end_entity_profile(cc)
    if cc.certificate.is_evcs?
        'EV_CS_CERT_EE'
    elsif cc.certificate.is_cs?
        'CS_CERT_EE'
    elsif cc.certificate.is_dv?
        'DV_SERVER_CERT_EE'
    elsif cc.certificate.is_ov?
        'OV_SERVER_CERT_EE'
    elsif cc.certificate.is_ev?
        'EV_SERVER_CERT_EE'
    end unless cc.certificate.blank?
  end

  def self.certificate_profile(options)
    if options[:cc].certificate.is_evcs?
      "EV_RSA_CS_CERT"
    elsif options[:cc].certificate.is_cs?
      "RSA_CS_CERT"
    else
      "#{options[:cc].certificate.validation_type.upcase}_#{sig_alg_parameter(options[:cc].csr)}_SERVER_CERT"
    end
  end

  def self.ca_name(options)
    if options[:ca]==SslcomCaApi::CERTLOCK_CA
      case options[:cc].certificate.product
        when /^ev/
          sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'CertLock-SubCA-EV-SSL-RSA-4096' :
              'CertLockEVECCSSLsubCA'
        else
          sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'CertLock-SubCA-SSL-RSA-4096' :
              'CertLockECCSSLsubCA'
      end unless options[:cc].certificate.blank?
    end
  end

  # revoke json parameter string for REST call to EJBCA
  def self.revoke_cert_json(signed_certificate, reason)
    {issuer_dn: signed_certificate.openssl_x509.issuer.to_s.split("/").reject(&:empty?).join(","),
     certificate_serial_number: signed_certificate.openssl_x509.serial.to_s(16).downcase,
     revocation_reason: reason}.to_json
  end

  # create json parameter string for REST call to EJBCA
  def self.issue_cert_json(options)
    {subject_dn: options[:subject_dn] || options[:cc].subject_dn,
     ca_name: ca_name(cc: options[:cc], ca: SslcomCaApi::CERTLOCK_CA),
     certificate_profile: certificate_profile(cc: options[:cc]),
     end_entity_profile: end_entity_profile(options[:cc]),
     duration: "#{options[:cc].certificate_order.certificate_duration(:sslcom_api)}:0:0" || options[:duration],
     subject_alt_name: options[:cc].all_domains.map{|domain| options[:cc].certificate.is_smime? ? "rfc822Name=" :
                                                                 "dNSName=" +domain.downcase}.join(","),
     pkcs10: Csr.remove_begin_end_tags(options[:cc].csr.body)}.to_json if options[:cc].csr
  end

  def self.apply_for_certificate(certificate_order, options={})
    cc = options[:certificate_content] || certificate_order.certificate_content
    host = APPLY_SSL_URL
    uri = URI.parse(host)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = issue_cert_json(cc: cc)
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    api_log_entry=cc.csr.sslcom_ca_requests.create(request_url: host,
      parameters: req.body, method: "post", response: res.try(:body), ca: "sslcom")
    unless api_log_entry.username
      OrderNotifier.problem_ca_sending("support@ssl.com", cc.certificate_order,"sslcom").deliver
    else
      cc.update_column(:ref, api_log_entry.username) unless api_log_entry.blank?
      cc.csr.signed_certificates.create body: api_log_entry.end_entity_certificate.to_s
    end
    api_log_entry
  end

  def self.revoke_ssl(signed_certificate, reason)
    if signed_certificate.is_sslcom_ca?
      host = REVOKE_SSL_URL
      uri = URI.parse(host)
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = revoke_cert_json(signed_certificate, reason)
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
      api_log_entry=signed_certificate.sslcom_ca_revocation_requests.create(request_url: host,
                                                                            parameters: req.body, method: "post", response: res.message, ca: "sslcom")
      unless api_log_entry.response=="OK"
        OrderNotifier.problem_ca_sending("support@ssl.com", signed_certificate.certificate_order,"sslcom").deliver
      else
        signed_certificate.revoke! reason
      end
      api_log_entry
    end
  end


#  def self.test
#    ssl_util = Savon::Client.new "http://ccm-host/ws/EPKIManagerSSL?wsdl"
#    begin
#      response = ssl_util.enroll do |soap|
#        soap.body = {:csr => csr}
#      end
#    rescue

#    client = Savon::Client.new do |wsdl, http|
#      wsdl.document = "http://ccm-host/ws/EPKIManagerSSL?wsdl"
#    end
#    client.wsdl.soap_actions
#  end
end

