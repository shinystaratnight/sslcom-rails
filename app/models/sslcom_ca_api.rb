require 'net/http'
require 'net/https'
require 'open-uri'

class SslcomCaApi

  # DV_ECC_SERVER_CERT is linked to the
  # CertLockECCSSLsubCA
  # SSLcom-SubCA-SSL-ECC-384-R1
  # ManagementCA

  SIGNATURE_HASH = %w(NO_PREFERENCE INFER_FROM_CSR PREFER_SHA2 PREFER_SHA1 REQUIRE_SHA2)
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
  def self.end_entity_profile(options)
    if options[:cc].certificate.is_evcs?
        'EV_CS_CERT_EE'
    elsif options[:cc].certificate.is_cs?
        'CS_CERT_EE'
    elsif options[:cc].certificate.is_dv?
        'DV_SERVER_CERT_EE'
    elsif options[:cc].certificate.is_ov?
        'OV_SERVER_CERT_EE'
    elsif options[:cc].certificate.is_ev?
        'EV_SERVER_CERT_EE'
    end unless options[:cc].certificate.blank?
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
    if options[:ca]==Ca::CERTLOCK_CA
      case options[:cc].certificate.product
        when /^ev/
          sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'CertLock-SubCA-EV-SSL-RSA-4096' :
              'CertLockEVECCSSLsubCA'
        else
          sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'CertLock-SubCA-SSL-RSA-4096' :
              'CertLockECCSSLsubCA'
      end
    elsif options[:ca]==Ca::SSLCOM_CA
      case options[:cc].certificate.validation_type
        when "ev"
          sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'SSLcom-SubCA-EV-SSL-RSA-4096-R2' :
              'SSLcom-SubCA-EV-SSL-ECC-384-R1'
        when "evcs"
          'SSLcom-SubCA-EV-CodeSigning-RSA-4096-R2'
        when "cs"
          'SSLcom-SubCA-CodeSigning-RSA-4096-R1'
        else
          sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'CertLock-SubCA-SSL-RSA-4096' :
              'SSLcom-SubCA-SSL-ECC-384-R1'
      end
    else
      'ManagementCA'
    end unless options[:cc].certificate.blank?
  end

  def self.subject_dn(options={})
    dn=["CN=#{options[:cn]}"]
    dn << "O=#{options[:o]}" unless options[:o].blank?
    dn << "OU=#{options[:ou]}" unless options[:ou].blank?
    dn << "OU=Key Hash #{options[:cc].csr.sha2_hash}"
    dn << "C=#{options[:country]}" unless options[:country].blank?
    dn << "L=#{options[:city]}" unless options[:city].blank?
    dn << "ST=#{options[:state]}" unless options[:state].blank?
    dn << "postalCode=#{options[:postal_code]}" unless options[:postal_code].blank?
    dn << "postalAddress=#{options[:postal_address]}" unless options[:postal_address].blank?
    dn << "streetAddress=#{options[:street_address]}" unless options[:street_address].blank?
    dn << "serialNumber=#{options[:serial_number]}" unless options[:serial_number].blank?
    dn << "2.5.4.15=#{options[:business_category]}" unless options[:business_category].blank?
    dn << "1.3.6.1.4.1.311.60.2.1.1=#{options[:joi_locality]}" unless options[:joi_locality].blank?
    dn << "1.3.6.1.4.1.311.60.2.1.2=#{options[:joi_state]}" unless options[:joi_state].blank?
    dn << "1.3.6.1.4.1.311.60.2.1.3=#{options[:joi_country]}" unless options[:joi_country].blank?
                                          # =text_area_tag :csr, @certificate_order.certificate_content.csr.body
                                          #    =text_area_tag :san, @certificate_order.all_domains.join("\n"),readonly: true


    dn.join(",")
  end

  def self.subject_alt_name(options)
    cert = options[:cc].certificate
    if cert.is_smime?
      "rfc822Name="
    elsif !cert.is_code_signing?
      (options[:san] ? options[:san].split(/\s+/) : options[:cc].all_domains).map{|d|"dNSName="+d.downcase}.join(",")
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
    cert = options[:cc].certificate
    if options[:cc].csr
      dn={subject_dn: options[:action]=="send_to_ca" ? subject_dn(options) : # req sent via RA form
                       (options[:subject_dn] || options[:cc].subject_dn),
       ca_name: ca_name(options),
       certificate_profile: certificate_profile(options),
       end_entity_profile: end_entity_profile(options),
       duration: "#{options[:cc].certificate_order.certificate_duration(:sslcom_api)}:0:0" || options[:duration],
       pkcs10: Csr.remove_begin_end_tags(options[:cc].csr.body)}
      dn.merge!(subject_alt_name: subject_alt_name(options)) unless cert.is_code_signing?
      dn.to_json
    end
  end

  def self.apply_for_certificate(certificate_order, options={})
    options.merge! cc: cc = options[:certificate_content] || certificate_order.certificate_content
    host = Rails.application.secrets.sslcom_ca_host+"/v1/certificate/pkcs10"
    req, res = call_ca(host, options, issue_cert_json(options))
    cc.create_csr(body: options[:csr]) if cc.csr.blank?
    api_log_entry=cc.csr.sslcom_ca_requests.create(request_url: host,
      parameters: req.body, method: "post", response: res.try(:body), ca: options[:ca])
    unless api_log_entry.username
      OrderNotifier.problem_ca_sending("support@ssl.com", cc.certificate_order,"sslcom").deliver
    else
      cc.update_column(:ref, api_log_entry.username) unless api_log_entry.blank?
      cc.csr.signed_certificates.create body: api_log_entry.end_entity_certificate.to_s, ca_id: options[:ca_id]
      SystemAudit.create(
          owner:  options[:current_user],
          target: api_log_entry,
          notes:  "issued signed certificate for certificate order #{certificate_order.ref}",
          action: "SslcomCaApi#apply_for_certificate"
      )
    end
    api_log_entry
  end

  def self.subject_dn_from_csr(options={})
    dn=["CN=#{options[:common_name]}"]
    dn << "O=#{options[:organization]}" unless options[:organization].blank?
    dn << "OU=#{options[:organization_unit]}" unless options[:organization_unit].blank?
    dn << "OU=Key Hash #{options.sha2_hash}"
    dn << "C=#{options[:country]}" unless options[:country].blank?
    dn << "L=#{options[:locality]}" unless options[:locality].blank?
    dn << "ST=#{options[:state]}" unless options[:state].blank?
    # dn << "postalCode=#{options[:postal_code]}" unless options[:postal_code].blank?
    # dn << "postalAddress=#{options[:postal_address]}" unless options[:postal_address].blank?
    # dn << "streetAddress=#{options[:street_address]}" unless options[:street_address].blank?
    # dn << "serialNumber=#{options[:serial_number]}" unless options[:serial_number].blank?
    # dn << "2.5.4.15=#{options[:business_category]}" unless options[:business_category].blank?
    # dn << "1.3.6.1.4.1.311.60.2.1.1=#{options[:joi_locality]}" unless options[:joi_locality].blank?
    # dn << "1.3.6.1.4.1.311.60.2.1.2=#{options[:joi_state]}" unless options[:joi_state].blank?
    # dn << "1.3.6.1.4.1.311.60.2.1.3=#{options[:joi_country]}" unless options[:joi_country].blank?
    # =text_area_tag :csr, @certificate_order.certificate_content.csr.body
    #    =text_area_tag :san, @certificate_order.all_domains.join("\n"),readonly: true


    dn.join(",")
  end

  def self.generate_for_certificate(csrStr)
    csr = Csr.new(body: csrStr)
    host = Rails.application.secrets.sslcom_ca_host + "/v1/certificate/pkcs10"

    options = {}
    options['subject_dn'] = subject_dn_from_csr(csr)
    options['ca_name'] = 'ManagementCA'
    options['certificate_profile'] = 'RSA_CS_CERT'
    options['end_entity_profile'] = 'CS_CERT_EE'
    options['duration'] = '365:0:0'
    options['pkcs10'] = Csr.remove_begin_end_tags(csrStr)

    req, res = call_ca(host, nil, options.to_json)

    res.body
  end

  def self.revoke_ssl(signed_certificate, reason)
    if signed_certificate.is_sslcom_ca?
      host = Rails.application.secrets.sslcom_ca_host+"/v1/certificate/revoke"
      req, res = call_ca(host, options, revoke_cert_json(signed_certificate, SslcomCaRevocationRequest::REASONS[0]))
      uri = URI.parse(host)
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

  private
  def self.call_ca(host, options, body)
    uri = URI.parse(host)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req.body = body
    res = http.request(req)
    return req, res
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

