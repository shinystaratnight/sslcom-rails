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

  def self.apply_for_certificate(certificate_order)
    options = certificate_order.options_for_ca.
        merge(CREDENTIALS).map{|k,v|"#{k}=#{v}"}.join("&")
    #reprocess or new?
    host = options["orderNumber"] ? REPLACE_SSL_URL : APPLY_SSL_URL
    url = URI.parse(host)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    res = con.start do |http|
      http.request_post(url.path, options)
    end
    certificate_order.certificate_content.csr.ca_certificate_requests.create(request_url: host,
      parameters: options, method: "post", response: res.body, ca: "comodo")
  end

  def self.domain_control_email_choices(csr_or_domain)
    is_a_csr = csr_or_domain.is_a?(Csr) ? true : false
    options = {'domainName' => is_a_csr ? csr_or_domain.try(:common_name) : csr_or_domain}.
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
    if is_a_csr
      dcv=csr_or_domain.ca_dcv_requests.create(attr)
      csr_or_domain.domain_control_validations.create(
        candidate_addresses: dcv.email_address_choices, subject: dcv.domain_name)
      dcv
    else
      CaDcvRequest.new(attr)
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

