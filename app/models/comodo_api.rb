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
  COLLECT_SSL_URL="https://secure.comodo.net/products/download/CollectSSL"
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
    cc.csr.ca_certificate_requests.create(request_url: host,
      parameters: comodo_options, method: "post", response: res.try(:body), ca: "comodo")
  end

  def self.domain_control_email_choices(obj_or_domain)
    is_a_obj = (obj_or_domain.is_a?(Csr) or obj_or_domain.is_a?(CertificateName)) ? true : false
    options = {'domainName' => is_a_obj ? obj_or_domain.try(:common_name) : obj_or_domain}.
        merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    host = "https://secure.comodo.net/products/!GetDCVEmailAddressList"
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    res = con.start do |http|
      http.request_post(url.path, options)
    end
    attr = {request_url: host,
      parameters: options, method: "post", response: res.body, ca: "comodo"}
    if is_a_obj
      dcv=obj_or_domain.ca_dcv_requests.create(attr)
      obj_or_domain.domain_control_validations.create(
        candidate_addresses: dcv.email_address_choices, subject: dcv.domain_name)
      dcv
    else
      CaDcvRequest.new(attr)
    end
  end

  def self.resend_dcv(dcv)
    options = {'dcvEmailAddress' => dcv.email_address, 'orderNumber'=> dcv.csr.sent_success(true).order_number}.
        merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    host = RESEND_DCV_URL
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    res = con.start do |http|
      http.request_post(url.path, options)
    end
    attr = {request_url: host,
      parameters: options, method: "post", response: res.body, ca: "comodo", api_requestable: dcv.csr}
    CaDcvResendRequest.create(attr)
  end

  def self.collect_ssl(certificate_order, options={})
    comodo_params = {'queryType' => 2, "showExtStatus"=>"Y", "responseType"=>"3",
               'orderNumber'=> certificate_order.external_order_number_for_extract}
    comodo_params.reverse_merge!("queryType"=>1, "responseType"=>RESPONSE_TYPE[options[:response_type]]) if options[:response_type]
    comodo_params.reverse_merge!("queryType"=>1, "responseType"=>RESPONSE_TYPE[options[:response_type]],
       "responseEncoding"=>RESPONSE_ENCODING[options[:response_encoding]].to_i) if ["zip","pkcs7"].include?(options[:response_type]) &&
        options[:response_encoding]=="binary"
    # comodo_params.merge!("showMDCDomainDetail"=>"Y", "showMDCDomainDetail2"=>"Y") if certificate_order.certificate.is_ucc?
    comodo_options = comodo_params.merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    host = COLLECT_SSL_URL
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    res = con.start do |http|
      http.request_post(url.path, comodo_options)
    end
    attr = {request_url: host,
      parameters: comodo_options, method: "post", response: res.body, ca: "comodo", api_requestable: certificate_order}
    CaRetrieveCertificate.create(attr)
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

