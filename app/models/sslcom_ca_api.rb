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
    if options[:mapping]
      options[:mapping].end_entity
    elsif options[:cc].certificate.is_evcs?
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
    if options[:mapping]
      options[:mapping].profile_name
    elsif options[:cc].certificate.is_evcs?
      "EV_RSA_CS_CERT"
    elsif options[:cc].certificate.is_cs?
      "RSA_CS_CERT"
    else
      "#{options[:cc].certificate.validation_type.upcase}_#{sig_alg_parameter(options[:cc].csr)}_SERVER_CERT"
    end
  end

  def self.ca_name(options)
    if options[:mapping]
      options[:mapping].ca_name
    elsif options[:ca]==Ca::CERTLOCK_CA
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
    dn << "OU=#{options[:ou]}" unless options[:ou].blank?
    unless options[:mapping].profile_name =~ /DV/
      dn << "O=#{options[:o]}" unless options[:o].blank?
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
    end
    dn.map{|d|d.gsub(/\\/,'\\\\').gsub(',','\,')}.join(",")
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
      dn={}
      if options[:collect_certificate]
        dn.merge! user_name: options[:username]
      else
        # dn.merge! subject_dn: options[:action]=="send_to_ca" ? subject_dn(options) : # req sent via RA form
        #                           (options[:subject_dn] || options[:cc].subject_dn),
        dn.merge! subject_dn: (options[:action]=="send_to_ca" ? subject_dn(options) : # req sent via RA form
          (options[:subject_dn] || cert.is_code_signing? ? options[:cc].locked_subject_dn : options[:cc].subject_dn))+
            ",OU=Key Hash #{options[:cc].csr.sha2_hash}",
          ca_name: options[:ca_name] || ca_name(options),
          certificate_profile: certificate_profile(options),
          end_entity_profile: end_entity_profile(options),
          duration: "#{options[:cc].certificate_order.certificate_duration(:sslcom_api)}:0:0" || options[:duration]
        dn.merge!(subject_alt_name: subject_alt_name(options)) unless cert.is_code_signing?
      end
      dn.merge!(request_type: "public_key",request_data: options[:cc].csr.public_key.to_s) if
          options[:collect_certificate] or options[:no_public_key].blank?
      dn.to_json
    end
  end

  def self.apply_for_certificate(certificate_order, options={})
    certificate = certificate_order.certificate
    options.merge! cc: cc = options[:certificate_content] || certificate_order.certificate_content
    options[:mapping] = Ca.find_by_ref(options[:send_to_ca]) if options[:send_to_ca]
    approval_req, approval_res = SslcomCaApi.get_status(cc.csr)
    return cc.csr.sslcom_ca_requests.create(
      parameters: approval_req.body, method: "get", response: approval_res.body,
                                            ca: options[:ca]) if approval_res.try(:body)=~/WAITING FOR APPROVAL/
    if (certificate.is_ev? or certificate.is_evcs?) and
        (approval_res.try(:body).blank? or approval_res.try(:body)=~/EXPIRED AND NOTIFIED/)
      # create the user for EV order
      host = Rails.application.secrets.sslcom_ca_host+"/v1/user"
      options.merge! no_public_key: true, ca: Ca::SSLCOM_CA # create an ejbca user only
    else # collect ev cert
      host = Rails.application.secrets.sslcom_ca_host+
          "/v1/certificate#{'/ev' if certificate.is_ev? or certificate.is_evcs?}/pkcs10"
      options.merge!(collect_certificate: true, username:
          cc.csr.sslcom_usernames.compact.first) if certificate.is_ev? or certificate.is_evcs?
    end
    req, res = call_ca(host, options, issue_cert_json(options))
    cc.create_csr(body: options[:csr]) if cc.csr.blank?
    api_log_entry=cc.csr.sslcom_ca_requests.create(request_url: host,
      parameters: req.body, method: "post", response: res.try(:body), ca: options[:ca])
    if api_log_entry.username.blank?
      OrderNotifier.problem_ca_sending("support@ssl.com", cc.certificate_order,"sslcom").deliver
    elsif api_log_entry.certificate_chain # signed certificate is issued
      cc.update_column(:ref, api_log_entry.username) unless api_log_entry.blank?
      attrs = {body: api_log_entry.end_entity_certificate.to_s, ca_id: options[:mapping].id}
      attrs.merge!(type: "ShadowSignedCertificate") if certificate.cas.shadow.include?(options[:mapping])
      cc.csr.signed_certificates.create(attrs)
      SystemAudit.create(
          owner:  options[:current_user],
          target: api_log_entry,
          notes:  "issued signed certificate for certificate order #{certificate_order.ref}",
          action: "SslcomCaApi#apply_for_certificate"
      )
    else # still waiting for approval

    end
    api_log_entry
  end

  def self.generate_for_certificate(options={})
    host = (options[:mapping] ? options[:mapping].host :
                   Rails.application.secrets.sslcom_ca_host) + "/v1/certificate/pkcs10"
    req, res = call_ca(host, {}, issue_cert_json(options))

    api_log_entry = options[:cc].csr.sslcom_ca_requests.create(request_url: host, parameters: req.body,
                                               method: 'post', response: res.try(:body), ca: options[:ca])

    unless api_log_entry.username
      OrderNotifier.problem_ca_sending("support@ssl.com", options[:cc].certificate_order,"sslcom").deliver
    else
      options[:cc].update_column(:ref, api_log_entry.username) unless api_log_entry.blank?
      # options[:cc].csr.signed_certificates.create body: api_log_entry.end_entity_certificate.to_s, ca_id: options[:ca_id]
    end

    api_log_entry.end_entity_certificate.to_s
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

  def self.get_status(csr=nil,host_only=false)
    unless csr.blank?
      return if csr.sslcom_approval_ids.compact.first.blank?
      query="status/#{csr.sslcom_approval_ids.compact.first}"
    else
      query="approvals"
    end
    host = Rails.application.secrets.sslcom_ca_host+"/v1/#{query}"
    if host_only
      host
    else
      options={method: "get"}
      body = ""
      call_ca(host, options, body)
    end
  end

  def self.unique_id(approval_id)
    req,res = get_status
    JSON.parse(res.body).select{|approval|approval[1]==approval_id.to_i}.first[0] unless res.body.blank?
  end

  private

  # body - parameters in JSON format
  def self.call_ca(host, options, body)
    uri = URI.parse(host)
    req = (options[:method]=~/GET/i ? Net::HTTP::Get : Net::HTTP::Post).new(uri, 'Content-Type' => 'application/json')
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

