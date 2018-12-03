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

  PRODUCTION_IP = "192.168.5.17"
  STAGING_IP = "192.168.5.19"
  DEVELOPMENT_IP = "192.168.100.5"

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
    elsif options[:cc] and options[:cc].ca
      options[:cc].ca.ca_name
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
    dn=["CN=#{options[:cn].downcase}"]
    unless options[:mapping].profile_name =~ /DV/
      dn << "O=#{options[:o]}" unless options[:o].blank?
      dn << "OU=#{options[:ou]}" unless options[:ou].blank?
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
    common_name=options[:cc].csr.common_name
    names=if cert.is_smime?
      "rfc822Name="
    elsif !cert.is_code_signing?
      (options[:san] ? options[:san].split(/\s+/) : options[:cc].all_domains).map{|d|d.downcase}
    end || ""
    names << if cert.is_wildcard?
      "#{CertificateContent.non_wildcard_name(common_name)}"
    elsif cert.is_single?
      if common_name=~/\Awww\./
        "#{common_name[4..-1]}"
      else
        "www.#{common_name}"
      end
    end
    "dNSName=#{names.compact.map(&:downcase).uniq.join(",dNSName=")}"
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
    co=options[:cc].certificate_order
    carry_over = co.certificate.is_free? ? 0 : options[:cc].csr.days_left
    if options[:cc].csr
      options[:mapping]=options[:mapping].ecc_profile if options[:cc].csr.sig_alg_parameter=~/ecc/i
      dn={}
      if options[:collect_certificate]
        dn.merge! user_name: options[:username]
      else
        dn.merge! subject_dn: (options[:action]=="send_to_ca" ? subject_dn(options) : # via RA form or shadow
          (options[:subject_dn] || options[:cc].subject_dn({mapping: options[:mapping]})))+
            ",OU=#{Digest::SHA1.hexdigest(options[:cc].csr.to_der+DateTime.now.to_i.to_s).upcase}",
          ca_name: options[:ca_name] || ca_name(options),
          certificate_profile: certificate_profile(options),
          end_entity_profile: end_entity_profile(options),
          duration: "#{[(options[:duration] || co.remaining_days+carry_over).to_i,
              cert.max_duration].min.floor}:0:0"
        dn.merge!(subject_alt_name: subject_alt_name(options)) unless cert.is_code_signing?
      end
      dn.merge!(request_type: "public_key",request_data: options[:cc].csr.public_key.to_pem) if
          options[:collect_certificate] or options[:no_public_key].blank?
      dn.to_json
    end
  end

  def self.apply_for_certificate(certificate_order, options={})
    certificate = certificate_order.certificate
    if options[:send_to_ca]
      options[:mapping] = Ca.find_by_ref(options[:send_to_ca])
    elsif options[:mapping].blank?
      options[:mapping] = certificate_order.certificate_content.ca
    end

    # does this need to be a DV if OV is required but not satisfied?
    if options[:mapping].profile_name=~/OV/ or options[:mapping].profile_name=~/EV/
      downstep = !certificate_order.ov_validated?
      options[:mapping]=options[:mapping].downstep if downstep
    end

    options.merge! cc: cc = options[:certificate_content] || certificate_order.certificate_content
    approval_req, approval_res = SslcomCaApi.get_status(csr: cc.csr, mapping: options[:mapping])
    return cc.csr.sslcom_ca_requests.create(
      parameters: approval_req.body, method: "get", response: approval_res.body,
                                            ca: options[:ca]) if approval_res.try(:body)=~/WAITING FOR APPROVAL/
    if (certificate.is_ev? or certificate.is_evcs?) and
        (approval_res.try(:body).blank? or approval_res.try(:body)=~/EXPIRED AND NOTIFIED/)
      # create the user for EV order
      host = ca_host(options[:mapping])+"/v1/user"
      options.merge! no_public_key: true, ca: Ca::SSLCOM_CA # create an ejbca user only
    else # collect ev cert
      host = ca_host(options[:mapping])+
          "/v1/certificate#{'/ev' if certificate.is_ev? or certificate.is_evcs?}/pkcs10"
      options.merge!(collect_certificate: true, username:
          cc.csr.sslcom_usernames.compact.first) if certificate.is_ev? or certificate.is_evcs?
    end
    req, res = call_ca(host, options, issue_cert_json(options))
    cc.create_csr(body: options[:csr]) if cc.csr.blank?
    api_log_entry=cc.csr.sslcom_ca_requests.create(request_url: host,
      parameters: req.body, method: "post", response: res.try(:body), ca: options[:ca_name] || ca_name(options))
    if api_log_entry.username.blank?
      OrderNotifier.problem_ca_sending("support@ssl.com", cc.certificate_order,"sslcom").deliver
    elsif api_log_entry.certificate_chain # signed certificate is issued
      cc.update_column(:ref, api_log_entry.username) unless api_log_entry.blank?
      attrs = {body: api_log_entry.end_entity_certificate.to_s, ca_id: options[:mapping].id}
      cc.csr.signed_certificates.create(attrs)
      SystemAudit.create(
          owner:  options[:current_user],
          target: api_log_entry,
          notes:  "issued signed certificate for certificate order #{certificate_order.ref}",
          action: "SslcomCaApi#apply_for_certificate"
      )
    end
    api_log_entry
  end

  def self.ca_host(mapping=nil)
    mapping ? mapping.host : Rails.application.secrets.sslcom_ca_host
  end

  def self.generate_for_certificate(options={})
    host = ca_host(options[:mapping]) + "/v1/certificate/pkcs10"
    req, res = call_ca(host, {}, issue_cert_json(options))

    api_log_entry = options[:cc].csr.sslcom_ca_requests.create(request_url: host, parameters: req.body,
                                   method: 'post', response: res.try(:body), ca: options[:ca_name] || ca_name(options))

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
      host = ca_host(signed_certificate.certificate_content.ca)+"/v1/certificate/revoke"
      req, res = call_ca(host, {}, revoke_cert_json(signed_certificate, SslcomCaRevocationRequest::REASONS[0]))
      api_log_entry=signed_certificate.sslcom_ca_revocation_requests.create(request_url: host,
                        parameters: req.body, method: "post", response: res.message, ca: "sslcom")
      unless api_log_entry.response=="OK"
        OrderNotifier.problem_ca_sending("support@ssl.com", signed_certificate.certificate_order,"sslcom").deliver
      end
      api_log_entry
    end
  end

  def self.get_status(options={csr: nil,host_only: false})
    unless options[:csr].blank?
      return if options[:csr].sslcom_approval_ids.compact.first.blank?
      query="status/#{options[:csr].sslcom_approval_ids.compact.first}"
    else
      query="approvals"
    end
    host = ca_host(options[:csr] ? options[:csr].certificate_content.ca : options[:mapping])+"/v1/#{query}"
    if options[:host_only]
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
    client_auth_cert,client_auth_key= case uri.host
                 when PRODUCTION_IP
                   [Rails.application.secrets.ejbca_production_client_auth_cert,
                       Rails.application.secrets.ejbca_production_client_auth_key]
                 when DEVELOPMENT_IP
                   [Rails.application.secrets.ejbca_development_client_auth_cert,
                       Rails.application.secrets.ejbca_development_client_auth_key]
                 when STAGING_IP
                   [Rails.application.secrets.ejbca_staging_client_auth_cert,
                       Rails.application.secrets.ejbca_staging_client_auth_key]
                 end
    req = (options[:method]=~/GET/i ? Net::HTTP::Get : Net::HTTP::Post).new(uri, 'Content-Type' => 'application/json')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert = OpenSSL::X509::Certificate.new(File.read(client_auth_cert))
    http.key = OpenSSL::PKey::RSA.new(File.read(client_auth_key))
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

