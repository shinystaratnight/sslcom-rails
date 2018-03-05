require 'net/http'
require 'net/https'
require 'open-uri'

class ComodoApi
  CREDENTIALS={
    'loginName' => Rails.application.secrets.comodo_api_username,
    'loginPassword' => Rails.application.secrets.comodo_api_password
  }

  CODE_SIGNING_PRODUCT={"1"=>"x_PPP=1511", "2"=>"x_PPP=1512", "3"=>"x_PPP=1509"}
  SIGNATURE_HASH = %w(NO_PREFERENCE INFER_FROM_CSR PREFER_SHA2 PREFER_SHA1 REQUIRE_SHA2)
  REPLACE_SSL_URL="https://secure.comodo.net/products/!AutoReplaceSSL"
  APPLY_SSL_URL="https://secure.comodo.net/products/!AutoApplySSL"
  PLACE_ORDER_URL="https://secure.comodo.net/products/!PlaceOrder"
  RESEND_DCV_URL="https://secure.comodo.net/products/!ResendDCVEmail"
  AUTO_UPDATE_URL="https://secure.comodo.net/products/!AutoUpdateDCV"
  AUTO_REMOVE_URL="https://secure.comodo.net/products/!AutoRemoveMDCDomain"
  REVOKE_SSL_URL="https://secure.comodo.net/products/!AutoRevokeSSL"
  COLLECT_SSL_URL="https://secure.comodo.net/products/download/CollectSSL"
  GET_MDC_DETAILS="https://secure.comodo.net/products/!GetMDCDomainDetails"
  RESPONSE_TYPE={"zip"=>0,"netscape"=>1, "pkcs7"=>2, "individually"=>3}
  RESPONSE_ENCODING={"base64"=>0,"binary"=>1}

  def self.auto_replace_ssl(options={})
    cc = options[:certificate_order].certificate_content
    options[:send_to_ca]=true unless options[:send_to_ca]==false
    comodo_params = {
        'orderNumber'=>options[:certificate_order].external_order_number,
        'domainNames'=>options[:domainNames],
        # 'dcvEmailAddresses'=>options[:domainDcvs],
        'isCustomerValidated'=>'N'
    }
    comodo_params = comodo_params.merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")

    host = REPLACE_SSL_URL
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    cc.csr.touch
    res = unless [false,"false"].include? options[:send_to_ca]
            con.start do |http|
              http.request_post(url.path, comodo_params)
            end
          end
    ccr=cc.csr.ca_certificate_requests.create(request_url: host,
                                              parameters: comodo_params, method: "post", response: res.try(:body), ca: "comodo")

    unless ccr.success?
      OrderNotifier.problem_ca_sending("comodo@ssl.com", options[:certificate_order],"comodo").deliver
    else
      options[:certificate_order].update_column(:external_order_number, ccr.order_number) if ccr.order_number
    end
    res.try(:body)
  end

  def self.apply_for_certificate(certificate_order, options={})
    cc = options[:certificate_content] || certificate_order.certificate_content
    comodo_options = certificate_order.options_for_ca(options).
        merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    options.merge!(ca_certificate_id: certificate_order.signed_certificates.last.comodo_ca_id) if
        !certificate_order.signed_certificates.blank? and options[:ca_certificate_id].blank? and comodo_options["orderNumber"].blank?
    #reprocess or new?
    host = comodo_options["orderNumber"] ? REPLACE_SSL_URL : APPLY_SSL_URL
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    cc.csr.touch
    res = unless [false,"false"].include? options[:send_to_ca]
            con.start do |http|
              http.request_post(url.path, comodo_options)
            end
          end
    ccr=cc.csr.ca_certificate_requests.create(request_url: host,
      parameters: comodo_options, method: "post", response: res.try(:body), ca: "comodo")
    unless ccr.success?
      OrderNotifier.problem_ca_sending("comodo@ssl.com", certificate_order,"comodo").deliver
    else
      certificate_order.update_column(:external_order_number, ccr.order_number) if ccr.order_number
    end
    ccr
  end

  def self.domain_control_email_choices(obj_or_domain)
    is_a_obj = (obj_or_domain.is_a?(Csr) or obj_or_domain.is_a?(CertificateName)) ? true : false
    comodo_options = {'domainName' => is_a_obj ? obj_or_domain.try(:common_name) : obj_or_domain}.
        merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    host = "https://secure.comodo.net/products/!GetDCVEmailAddressList"
    res = send_comodo(host, comodo_options)
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo"}
    if is_a_obj
      dcv=obj_or_domain.ca_dcv_requests.create(attr)
      obj_or_domain.domain_control_validations.create(
        candidate_addresses: dcv.email_address_choices, subject: dcv.domain_name)
      dcv
    else
      CaDcvRequest.new(attr)
    end
  end

  def self.resend_dcv(options)
    owner = options[:dcv].csr || options[:dcv].certificate_name
    comodo_options = {'dcvEmailAddress' => options[:dcv].email_address,
                      'orderNumber'=> owner.certificate_content.certificate_order.external_order_number}.
                      merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    host = RESEND_DCV_URL
    res = send_comodo(host, comodo_options)
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: owner}
    CaDcvResendRequest.create(attr)
  end

  def self.auto_remove_domain(options={})
    owner = options[:domain_name]
    comodo_options = {'orderNumber'=>options[:order_number].to_i, 'domainName'=>owner.name}
    comodo_options = comodo_options.merge!(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")

    host = AUTO_REMOVE_URL
    res = send_comodo(host, comodo_options)

    attr = {
        request_url: host,
        parameters: comodo_options,
        method: "post",
        response: res.body,
        ca: "comodo",
        api_requestable: owner
    }

    CaDcvResendRequest.create(attr)
    res.body
  end

  # this is the only way to update multi domain dcv after the order is submitted
  def self.auto_update_dcv(options={})
    options[:send_to_ca]=true unless options[:send_to_ca]==false
    if options[:dcv].certificate_name #assume ucc
      owner = options[:dcv].certificate_name
      order_number = owner.certificate_content.certificate_order.external_order_number
      is_ucc=owner.certificate_content.certificate_order.certificate.is_ucc?
      domain_name = owner.name
      dcv_method=owner.last_dcv_for_comodo_auto_update_dcv
    else #assume single domain
      owner = options[:dcv]
      order_number = owner.csr.certificate_content.certificate_order.external_order_number
      is_ucc=owner.csr.certificate_content.certificate_order.certificate.is_ucc?
      domain_name = owner.csr.common_name
      dcv_method=CertificateName.to_comodo_method(owner.dcv_method)
    end
    comodo_options = {'orderNumber'=> order_number,
                      'newMethod'=>dcv_method}
    comodo_options.merge!('domainName'=>domain_name) if (is_ucc) #domain is no necessary for single name certs
    comodo_options.merge!('newDCVEmailAddress' => options[:dcv].email_address) if (options[:dcv].dcv_method=="email")
    comodo_options=comodo_options.merge!(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")

    if options[:send_to_ca] && order_number
      host = AUTO_UPDATE_URL
      res = send_comodo(host, comodo_options)
      attr = {request_url: host,
              parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: owner}
      CaDcvResendRequest.create(attr)
    else
      comodo_options
    end
  end

  def self.send_comodo(host, options={})
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    res = con.start do |http|
      http.request_post(url.path, options)
    end
  end

  def self.collect_ssl(certificate_order, options={})
    comodo_options = params_collect(certificate_order, options)
    host = COLLECT_SSL_URL
    res = send_comodo(host, comodo_options)
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: certificate_order}
    CaRetrieveCertificate.create(attr)
  end

  def self.revoke_ssl(options={})
    comodo_options = params_revoke(options)
    host = REVOKE_SSL_URL
    res = send_comodo(host, comodo_options)
    attr = {request_url: host, parameters: comodo_options, method: "post", response: res.body, ca: "comodo",
            api_requestable: options[:certificate_order] || options[:api_requestable]}
    CaRevokeCertificate.create(attr)
  end

  def self.apply_apac(certificate_order,options={})
    certificate = certificate_order.certificate
    registrant=certificate_order.certificate_content.registrant
    comodo_options = { # basic
        'ap' => 'SecureSocketsLaboratories',
        "reseller" => "Y",
        "1_PPP"=> ppp_parameter(certificate_order),
        "emailAddress"=>certificate_order.csr.common_name,
        "loginName"=>certificate_order.ref,
        "loginPassword"=>certificate_order.order.reference_number,
        "1_csr"=>certificate_order.csr.body,
        "caCertificateID"=> Settings.ca_certificate_id_client,
        "1_signatureHash"=>"PREFER_SHA2"}
    comodo_options.merge!( # pro
        "forename"=>registrant.first_name,
        "surname"=>registrant.last_name) unless certificate.product_root=~/basic/i
    comodo_options.merge!( # business
        "title"=>registrant.title,
        "organizationName"=>registrant.company_name,
        "postOfficeBox"=>registrant.po_box,
        "streetAddress1"=>registrant.address1,
        "streetAddress2"=>registrant.address2,
        "streetAddress3"=>registrant.address3,
        "localityName"=>registrant.city,
        "stateOrProvinceName"=>registrant.state,
        "postalCode"=>registrant.postal_code,
        "country"=>registrant.country,
        "telephoneNumber"=>registrant.phone,
        'orderNumber' => (options[:external_order_number] || certificate_order.external_order_number)) if
          certificate.product_root=~/enterprise\z/i || certificate.product_root=~/business\z/i
    comodo_options.merge!( # enterprise
        "organizationalUnitName"=>registrant.department) if certificate.product_root=~/enterprise\z/i
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
    # "title forename surname emailAddress x_PPP x_csr"
    # "title forename surname emailAddress organizationName organizationalUnitName streetAddress1 streetAddress2 streetAddress3 x_PPP x_csr localityName stateOrProvinceName postalCode countryName "
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

  # mdc = multi domain certificate
  def self.mdc_status(certificate_order)
    comodo_options = params_domains_status(certificate_order)
    host = GET_MDC_DETAILS
    res = send_comodo(host, comodo_options)
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: certificate_order}
    CaMdcStatus.create(attr)
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

  def self.ppp_parameter(certificate_order)
    certificate = certificate_order.certificate
    if certificate.is_code_signing?
      case certificate_order.certificate_duration(:years)
        when "1"
          "1511"
        when "2"
          "1512"
        when "3"
          "1509"
      end
    elsif certificate.is_client?
      if certificate.is_client_basic?
        case certificate_order.certificate_duration(:years)
          when "1"
            "5029"
          when "2"
            "5030"
          when "3"
            "5031"
        end
      elsif certificate.is_client_pro?
        case certificate_order.certificate_duration(:years)
          when "1"
            "5032"
          when "2"
            "5033"
          when "3"
            "5034"
        end
      elsif certificate.is_client_business? || certificate.is_client_enterprise?
        case certificate_order.certificate_duration(:years)
          when "1"
            "5035"
          when "2"
            "5036"
          when "3"
            "5037"
        end
      end
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

