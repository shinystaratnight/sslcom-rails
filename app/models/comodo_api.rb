require 'net/http'
require 'net/https'
require 'open-uri'

class ComodoApi
  CREDENTIALS={
      'loginName' => Settings.comodo_api_username,
      'loginPassword' => Settings.comodo_api_password}

  REPLACE_SSL_URL="https://secure.comodo.net/products/!AutoReplaceSSL"
  APPLY_SSL_URL="https://secure.comodo.net/products/!AutoApplySSL"
  RESEND_DCV_URL="https://secure.comodo.net/products/!ResendDCVEmail"
  AUTO_UPDATE_URL="https://secure.comodo.net/products/!AutoUpdateDCV"
  REVOKE_SSL_URL="https://secure.comodo.net/products/!AutoRevokeSSL"
  COLLECT_SSL_URL="https://secure.comodo.net/products/download/CollectSSL"
  GET_MDC_DETAILS="https://secure.comodo.net/products/!GetMDCDomainDetails"
  RESPONSE_TYPE={"zip"=>0,"netscape"=>1, "pkcs7"=>2, "individually"=>3}
  RESPONSE_ENCODING={"base64"=>0,"binary"=>1}

  def self.apply_for_certificate(certificate_order, options={})
    cc = options[:certificate_content] || certificate_order.certificate_content
    comodo_options = certificate_order.options_for_ca(options).
        merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
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
    OrderNotifier.problem_ca_sending("comodo@ssl.com", certificate_order,"comodo").deliver unless ccr.success?
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

    # curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d
    # "domainName=mgardenssl1.com&newMethod=EMAIL&newDCVEmailAddress=admin@mgardenssl1.com&
    # orderNumber=15681927&loginName=likx2m7j&loginPassword=Jimi15Kimi15" 'https://secure.comodo.net/products/!AutoUpdateDCV'
    # EMAIL
    # HTTP_CSR_HASH
    # HTTPS_CSR_HASH
    # CNAME_CSR_HASH
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

  def self.revoke_ssl(certificate_order,options={})
    comodo_options = params_revoke(certificate_order, options)
    host = REVOKE_SSL_URL
    res = send_comodo(host, comodo_options)
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: certificate_order}
    CaRetrieveCertificate.create(attr)
  end

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

  def self.params_revoke(certificate_order, options)
    comodo_params = {'revocationReason' => options[:refund_reason],
                     'orderNumber' => options[:external_order_number] || certificate_order.external_order_number}
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

