require 'net/http'
require 'net/https'
require 'open-uri'

class ComodoApi

  #
  def self.apply_for_certificate(certificate_order)
    options = certificate_order.options_for_ca

    host = "https://secure.comodo.net/products/!AutoApplySSL"
    url = URI.parse(host)
    req = Net::HTTP::Post.new(url.path)
    con = Net::HTTP.new(url.host, 443)
    con.verify_mode = OpenSSL::SSL::VERIFY_PEER
    con.ca_path = '/etc/ssl/certs' if File.exists?('/etc/ssl/certs') # Ubuntu
    con.use_ssl = true
    res = con.start do |http|
      options = options.map{|k,v|"#{k}=#{v}"}
      http.request_post('/products/!AutoApplySSL', options.join("&"))
    end
  end

  def self.test
#    ssl_util = Savon::Client.new "http://ccm-host/ws/EPKIManagerSSL?wsdl"
#    begin
#      response = ssl_util.enroll do |soap|
#        soap.body = {:csr => csr}
#      end
#    rescue

    client = Savon::Client.new do |wsdl, http|
      wsdl.document = "http://ccm-host/ws/EPKIManagerSSL?wsdl"
    end
    client.wsdl.soap_actions
  end

end

