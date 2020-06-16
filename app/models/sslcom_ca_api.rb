require 'net/http'
require 'net/https'
require 'open-uri'

class SslcomCaApi

  # DV_ECC_SERVER_CERT is linked to the
  # CertLockECCSSLsubCA
  # SSLcom-SubCA-SSL-ECC-384-R2
  # ManagementCA

  SIGNATURE_HASH = %w(NO_PREFERENCE INFER_FROM_CSR PREFER_SHA2 PREFER_SHA1 REQUIRE_SHA2)
  RESPONSE_TYPE={"zip"=>0,"netscape"=>1, "pkcs7"=>2, "individually"=>3}
  RESPONSE_ENCODING={"base64"=>0,"binary"=>1}

  PRODUCTION_IP = 'ejbca-g1a.int.ssl.com'
  STAGING_IP = '192.168.5.19'
  DEVELOPMENT_IP = 'calypso-dev-01.int.ssl.com'

  # using the csr, determine the algorithm used
  def self.sig_alg_parameter(csr)
    case csr.sig_alg
      when /rsa/i
        'RSA'
      when /ecdsa/i
        'ECC'
      when /dsa/i
        'DSA'
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
      'EV_RSA_CS_ULMT_CERT'
    elsif options[:cc].certificate.is_cs?
      'RSA_CS_ULMT_CERT'
    else
      "#{options[:cc].certificate.validation_type.upcase}_#{sig_alg_parameter(options[:cc].csr)}_SERVER_CERT"
    end
  end

  def self.ca_name(options)
    unless options[:cc].certificate.blank?
      ca_name=if options[:mapping]
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
                  sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'SSLcom-SubCA-EV-SSL-RSA-4096-R3' :
                      'SSLcom-SubCA-EV-SSL-ECC-384-R2'
                when "evcs"
                  'SSLcom-SubCA-EV-CodeSigning-RSA-4096-R3'
                when "cs"
                  'SSLcom-SubCA-CodeSigning-RSA-4096-R1'
                else
                  sig_alg_parameter(options[:cc].csr) =~ /rsa/i ? 'SSLcom-SubCA-SSL-RSA-4096' :
                      'SSLcom-SubCA-SSL-ECC-384-R2'
                end
              else
                'ManagementCA'
              end
      Ca::SSL_ACCOUNT_MAPPING[options[:cc].ssl_account.acct_number] &&
          Ca::SSL_ACCOUNT_MAPPING[options[:cc].ssl_account.acct_number][ca_name] ?
        Ca::SSL_ACCOUNT_MAPPING[options[:cc].ssl_account.acct_number][ca_name] : ca_name
    end
  end

  def self.subject_alt_name(options)
    cert = options[:cc].certificate
    common_name=options[:common_name]
    names=if cert.is_smime?
            "rfc822Name=#{options[:cc].certificate_order.get_recipient.email}"
          elsif cert.is_server?
            ([common_name]+(options[:san] ?
                options[:san].split(Certificate::DOMAINS_TEXTAREA_SEPARATOR) :
                                options[:cc].certificate_names.map(&:name))).uniq.map{|d|d.downcase}
          end || ""
    if cert.is_server?
      names <<  if cert.is_wildcard?
                  "#{CertificateContent.non_wildcard_name(common_name)}"
                elsif cert.is_single?
                  if common_name=~/\Awww\./
                    "#{common_name[4..-1]}"
                  else
                    "www.#{common_name}"
                  end
                end
      # replace dNSName= with iPAddress:1.2.3.4 for ip address
      "dNSName=#{names.compact.map(&:downcase).uniq.join(",dNSName=")}"
    else
      names
    end
  end

  # revoke json parameter string for REST call to EJBCA
  def self.revoke_cert_json(signed_certificate, reason)
    {issuer_dn: signed_certificate.openssl_x509.issuer.to_utf8,
     certificate_serial_number: signed_certificate.openssl_x509.serial.to_s(16).downcase,
     revocation_reason: reason}.to_json
  end

  # retrieve json parameter string for REST call to EJBCA
  # valid_only false means return also revoked and expired certs along with valid certs.
  # true means only return valid certs
  def self.retrieve_cert_json(options)
    {user_name: options[:user_name]}.to_json
  end

  # create json parameter string for REST call to EJBCA
  def self.issue_cert_json(options)
    cert = options[:cc].certificate
    co=options[:cc].certificate_order
    carry_over=0
    public_key=
        if options[:cc].attestation_certificate
          options[:cc].attestation_certificate.public_key
        elsif options[:public_key]
          options[:public_key]
        else
          csr=options[:csr] ? Csr.new(body: options[:csr]) : options[:cc].csr
          carry_over=(!cert.is_server? or cert.is_free?) ? 0 : csr.days_left
          options[:mapping]=options[:mapping].ecc_profile if csr&.sig_alg_parameter=~/ecc/i
          csr&.public_key
        end
    if public_key
      dn={}
      if options[:collect_certificate]
        dn.merge! user_name: options[:username]
      else
        (options[:common_name] ||= options[:cn] ||
          options[:cc].common_name) if cert.is_server?
        options[:common_name]=options[:common_name].downcase if options[:common_name]
        dn.merge! subject_dn: (options[:subject_dn] || options[:cc].subject_dn(options)),
          ca_name: options[:ca_name] || ca_name(options),
          certificate_profile: certificate_profile(options),
          end_entity_profile: end_entity_profile(options),
          subject_alt_name: subject_alt_name(options),
          duration: "#{[(options[:duration] || co.remaining_days+(carry_over || 0)).to_i,
              cert.max_duration].min.floor}:0:0"
        dn.merge!(email_address: options[:cc].certificate_order.get_recipient.email) if cert.is_smime?
      end
      dn.merge!(request_type: "public_key",request_data: public_key.to_pem) if
          options[:collect_certificate] or options[:no_public_key].blank?
      dn.to_json
    end
  end

  def self.set_mapping(certificate_order,options)
    options[:mapping] = Ca.find_by_ref(options[:send_to_ca]) if options[:send_to_ca]
    options[:mapping] = certificate_order.certificate_content.ca if options[:mapping].blank?

    # does this need to be a DV if OV is required but not satisfied?
    if certificate_order.certificate.is_server? and
        (options[:mapping].profile_name=~/OV/ or options[:mapping].is_ev?)
      downstep = !certificate_order.ov_validated?
      options[:mapping]=options[:mapping].downstep if downstep
    elsif certificate_order.certificate.is_document_signing? && options[:origin] == 'api'
      options[:mapping] = if certificate_order.certificate.is_client_pro?
                            'MYSSL_IV_RSA_SMIME_CERT'
                          else
                            'MYSSL_OV_RSA_SMIME_CERT'
                          end
    end
  end

  def self.apply_for_attestation(certificate_order, parsed, user_name = nil)
    options = {}

    set_mapping(certificate_order, options)
    options.merge! cc: cc = options[:certificate_content] || certificate_order.certificate_content

    approval_req, approval_res = get_attestation_status(options)
    return cc.sslcom_ca_requests.create(
        parameters: approval_req.body,
        method: "get",
        response: approval_res.body,
        ca: options[:ca]
    ) if approval_res.try(:body)=~/WAITING FOR APPROVAL/

    if user_name.blank?
      host = ca_host(options[:mapping]) + "/v1/user"
      options.merge! no_public_key: true,
                     public_key: parsed.public_key
    else
      host = ca_host(options[:mapping]) + "/v1/certificate/ev/pkcs10"
      options.merge! collect_certificate: true,
                     public_key: parsed.public_key,
                     username: user_name
    end

    req, res = call_ca(host, options, issue_cert_json(options))
    api_log_entry = cc.sslcom_ca_requests.create(
        request_url: host,
        parameters: req.body,
        method: "post",
        response: res.try(:body),
        ca: ca_name(options)
    )

    if api_log_entry.username.blank? and api_log_entry.request_username.blank?
      OrderNotifier.problem_ca_sending("support@ssl.com", cc.certificate_order, "sslcom").deliver
    elsif api_log_entry.certificate_chain # signed certificate is issued
      cc.update_column(:label, api_log_entry.request_username) unless api_log_entry.blank?

      attrs = {
          body: api_log_entry.end_entity_certificate.to_s,
          ca_id: options[:mapping].id
      }

      cc.attestation_certificates.create(attrs)

      SystemAudit.create(
          owner:  options[:current_user],
          target: api_log_entry,
          notes:  "issued signed certificate for certificate order #{certificate_order.ref}",
          action: "SslcomCaApi#apply_for_certificate"
      )
    end

    api_log_entry
  end

  def self.apply_for_certificate(certificate_order, options={})
    set_mapping(certificate_order, options)
    options.merge! cc: cc = options[:certificate_content] || certificate_order.certificate_content
    begin
      if cc.preferred_pending_issuance?
        return
      else
        cc.toggle_pending_issuance
      end
      if cc.csr.blank?
        if !options[:csr].blank?
          cc.create_csr(body: options[:csr])
        elsif cc.attestation_certificate
          csr=OpenSSL::X509::Request.new
          csr.public_key=cc.attestation_certificate.public_key
          cc.create_csr(body: csr.to_s)
        end
      else
        cc.csr.save if cc.csr.new_record?
      end
      if options[:mapping].is_ev? # has the CSR already been submitted and is waiting for approval?
        approval_req, approval_res = SslcomCaApi.get_status(csr: cc.csr, mapping: options[:mapping])
        # exit if the csr has been submitted but not approved yet
        return cc.csr.sslcom_ca_requests.create(
            parameters: approval_req.body, method: "get", response: approval_res.body,
            ca: options[:ca]) if approval_res.try(:body)=~/WAITING FOR APPROVAL/
      end
      if options[:mapping].is_ev? && (approval_res.try(:body).blank? || (approval_res.try(:body) == '[]') ||
        (cc.signed_certificate.present? && cc.csr.sslcom_ca_requests.compact.first&.username.present? &&
          (cc.signed_certificates.first.read_attribute(:ejbca_username) == cc.csr.sslcom_ca_requests.compact.first.username)))
        # create the user for EV order
        host = ca_host(options[:mapping]) + '/v1/user'
        options[:no_public_key] = true
      else # collect cert
        host = ca_host(options[:mapping]) + "/v1/certificate#{'/ev' if options[:mapping].is_ev?}/pkcs10"
        if options[:mapping].is_ev?
          options[:collect_certificate] = true
          options[:username] = cc.csr.sslcom_usernames.compact.first
        end
      end
      ca_json = issue_cert_json(options)
      if ca_json
        req, res = call_ca(host, options, ca_json)
        api_log_entry=cc.csr.sslcom_ca_requests.create(request_url: host,
                                                       parameters: req.body, method: "post", response: res.try(:body), ca: options[:ca_name] || ca_name(options))
        if (!options[:mapping].is_ev? and api_log_entry.username.blank?) or
            (options[:mapping].is_ev? and api_log_entry.username.blank? and
                api_log_entry.request_username.blank?)
          cc.preferred_process_pending_server_certificates = false
          cc.preferred_process_pending_server_certificates_will_change!
          OrderNotifier.problem_ca_sending("support@ssl.com", cc.certificate_order,"sslcom").deliver
        elsif api_log_entry.certificate_chain # signed certificate is issued
          cc.update_column(:label, options[:mapping].is_ev? ? api_log_entry.request_username :
                                       api_log_entry.username) unless api_log_entry.blank?
          attrs = {body: api_log_entry.end_entity_certificate.to_s, ca_id: options[:mapping].id,
                   ejbca_username: cc.csr.sslcom_ca_requests.compact.first.username}
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
    ensure
      cc.toggle_pending_issuance if cc.preferred_pending_issuance?
    end
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

    api_log_entry.end_entity_certificate
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

  def self.get_attestation_status(options)
    unless options[:cc].blank?
      return if options[:cc].sslcom_approval_ids.compact.first.blank?
      query = "status/#{options[:cc].sslcom_approval_ids.compact.first}"
    else
      query = "approvals"
    end

    host = ca_host(options[:cc] ? options[:cc].ca : options[:mapping]) + "/v1/#{query}"
    options = {method: "get"}
    call_ca(host, options, "")
  end

  def self.get_status(options={csr: nil,host_only: false})
    unless options[:csr].blank?
      approval=options[:csr].sslcom_approval_ids.compact.first
      return if approval.blank?
      query="status/#{approval}"
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
    body=JSON.parse(res.body)
    id=body.select{|approval|approval[1]==approval_id.to_i} unless body.blank?
    id.first[0] unless id.blank?
  end

  def self.client_certs(host)
    case host
    when PRODUCTION_IP
      [Rails.application.secrets.ejbca_production_client_auth_cert,
       Rails.application.secrets.ejbca_production_client_auth_key]
    when DEVELOPMENT_IP
      [Rails.application.secrets.ejbca_development_client_auth_cert,
       Rails.application.secrets.ejbca_development_client_auth_key]
    when STAGING_IP
      [Rails.application.secrets.ejbca_staging_client_auth_cert,
       Rails.application.secrets.ejbca_staging_client_auth_key]
    else
      [Rails.application.secrets.ejbca_production_client_auth_cert,
       Rails.application.secrets.ejbca_production_client_auth_key]
    end
  end

  private

  # body - parameters in JSON format
  def self.call_ca(host, options, body)
    uri = URI.parse(host)
    client_auth_cert,client_auth_key=client_certs(uri.host)
    req = (options[:method]=~/GET/i ? Net::HTTP::Get : Net::HTTP::Post).new(uri, 'Content-Type' => 'application/json')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 1200 # Default is 60 seconds
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
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
