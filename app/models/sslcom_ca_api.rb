require 'net/http'
require 'net/https'
require 'open-uri'

class SslcomCaApi

  # DV_ECC_SERVER_CERT is linked to the
  # CertLockECCSSLsubCA
  # SSLcom-SubCA-SSL-ECC-384-R1
  # ManagementCA

  CREDENTIALS={
    'loginName' => Rails.application.secrets.comodo_api_username,
    'loginPassword' => Rails.application.secrets.comodo_api_password
  }

  DEV_HOST = "http://192.168.100.5:8080/restapi"

  SIGNATURE_HASH = %w(NO_PREFERENCE INFER_FROM_CSR PREFER_SHA2 PREFER_SHA1 REQUIRE_SHA2)
  APPLY_SSL_URL=DEV_HOST+"/v1/certificate/pkcs10"
  REVOKE_SSL_URL=DEV_HOST+"/v1/certificate/revoke"
  COLLECT_SSL_URL="https://secure.comodo.net/products/download/CollectSSL"
  RESPONSE_TYPE={"zip"=>0,"netscape"=>1, "pkcs7"=>2, "individually"=>3}
  RESPONSE_ENCODING={"base64"=>0,"binary"=>1}

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

  # create json parameter string for REST call to EJBCA
  def self.ssl_cert_json(options)
    {subject_dn:"CN=#{options[:cc].csr.common_name || ''}",
     ca_name:"CertLock-SubCA-SSL-RSA-4096",
     certificate_profile:"#{options[:cc].validation_type.upcase}_#{sig_alg_parameter(options[:cc].csr)}_SERVER_CERT",
     end_entity_profile:"#{options[:cc].validation_type.upcase}_SERVER_CERT_EE",
     duration: "#{options[:cc].certificate_order.certificate_duration(:sslcom_api)}:0:0" || options[:duration],
     subject_alt_name: options[:cc].all_domains.map{|domain|"dNSName=#{domain}"}.join(","),
     pkcs10: Csr.remove_begin_end_tags(options[:cc].csr.body)}.to_json if options[:cc].csr
  end

  # create json parameter string for REST call to EJBCA
  # cc - certificate_content
  def self.revoke_cert_json(signed_certificate,reason)
    {subject_dn: signed_certificate.openssl_x509.subject.to_s,
     certificate_serial_number: signed_certificate.openssl_x509.serial,
     revocation_reason: reason}.to_json
  end

  def self.apply_for_certificate(certificate_content, options={})
    cc = options[:certificate_content] || certificate_content
    #reprocess or new?
    # host = comodo_options["orderNumber"] ? REPLACE_SSL_URL : APPLY_SSL_URL
    host = APPLY_SSL_URL
    uri = URI.parse(host)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = ssl_cert_json(cc: cc)
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
    host = REVOKE_SSL_URL
    uri = URI.parse(host)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body =     {issuer_dn: signed_certificate.openssl_x509.issuer.to_s.split("/").reject(&:empty?).join(","),
                    certificate_serial_number: signed_certificate.openssl_x509.serial.to_s(16).downcase,
                    revocation_reason: reason}.to_json
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

  def self.collect_ssl(certificate_order, options={})
    comodo_options = params_collect(certificate_order, options)
    host = COLLECT_SSL_URL
    res = send_comodo(host, comodo_options)
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: certificate_order}
    CaRetrieveCertificate.create(attr)
  end

  def self.apply_code_signing(certificate_order,options={}.reverse_merge!(send_to_ca: true))
    registrant=certificate_order.certificate_content.registrant
    comodo_options = {
        "loginName"=>certificate_order.ref,
        "loginPassword"=>certificate_order.order.reference_number,
        "emailAddress"=>registrant.email,
        'ap' => 'SecureSocketsLaboratories',
        "reseller" => "Y",
        "1_contactEmailAddress"=>registrant.email,
        "organizationName"=>registrant.company_name,
        "organizationalUnitName"=>registrant.department,
        "postOfficeBox"=>registrant.po_box,
        "streetAddress1"=>registrant.address1,
        "streetAddress2"=>registrant.address2,
        "streetAddress3"=>registrant.address3,
        "localityName"=>registrant.city,
        "stateOrProvinceName"=>registrant.state,
        "postalCode"=>registrant.postal_code,
        "country"=>registrant.country,
        "dunsNumber"=>"",
        "companyNumber"=>"",
        "1_csr"=>certificate_order.csr.body,
        "caCertificateID"=>Settings.ca_certificate_id_code_signing,
        "1_signatureHash"=>"PREFER_SHA2",
        "1_PPP"=> ppp_parameter(certificate_order),
        'orderNumber' => (options[:external_order_number] || certificate_order.external_order_number)}
    comodo_options=comodo_options.map { |k, v| "#{k}=#{CGI::escape(v) if v}" }.join("&")
    if options[:send_to_ca]
      host = PLACE_ORDER_URL
      res = send_comodo(host, comodo_options)
      attr = {request_url: host,
              parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: certificate_order}
      CaCertificateRequest.create(attr)
    else
      comodo_options
    end
  end

  def self.params_collect(certificate_order, options={})
    comodo_params = {'queryType' => 2, "showExtStatus" => "Y",
                     'baseOrderNumber' => certificate_order.external_order_number}
    comodo_params.merge!("queryType" => 1, "responseType" => RESPONSE_TYPE[options[:response_type]]) if options[:response_type]
    comodo_params.merge!("queryType" => 1, "responseType" => RESPONSE_TYPE[options[:response_type]],
                         "responseEncoding" => RESPONSE_ENCODING[options[:response_encoding]].to_i) if ["zip", "pkcs7"].include?(options[:response_type]) &&
        options[:response_encoding]=="binary"
    # comodo_params.merge!("showMDCDomainDetail"=>"Y", "showMDCDomainDetail2"=>"Y") if certificate_order.certificate.is_ucc?
    comodo_params.merge(CREDENTIALS).map { |k, v| "#{k}=#{v}" }.join("&")
  end

  def self.params_domains_status(certificate_order)
    comodo_params = {'showStatusDetails' => "Y", 'orderNumber' => certificate_order.external_order_number}
    comodo_params.merge(CREDENTIALS).map { |k, v| "#{k}=#{v}" }.join("&")
  end

  def self.params_revoke(options)
    target = if options[:serial]
               {'serialNumber' => options[:serial].upcase}
             else
               {'orderNumber' => options[:external_order_number] || options[:certificate_order].external_order_number}
             end
    comodo_params = {'revocationReason' => options[:refund_reason]}.merge(target)
    comodo_params.merge(CREDENTIALS).map { |k, v| "#{k}=#{v}" }.join("&")
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

