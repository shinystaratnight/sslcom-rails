require 'net/http'
require 'net/https'
require 'open-uri'

class ComodoApi

  def self.apply_for_certificate(certificate_order)
    options = certificate_order.options_for_ca.map{|k,v|"#{k}=#{v}"}.join("&")
    host = "https://secure.comodo.net/products/!AutoApplySSL"
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

  def self.domain_control_email_choices(certificate_order)
    options = certificate_order.options_for_ca.map{|k,v|"#{k}=#{v}"}.join("&")
    host = "https://secure.comodo.net/products/!AutoApplySSL"
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

