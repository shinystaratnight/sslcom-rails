require 'net/https'
require 'open-uri'
class ComodoApi

  def apply_for_certificate
    apply_location = "https://secure.comodo.net/products/!AutoApplySSL"

    url = URI.parse('https://MY_URL')
    req = Net::HTTP::Post.new(url.path)
    req.form_data = data
    req.basic_auth url.user, url.password if url.user
    con = Net::HTTP.new(url.host, url.port)
    con.use_ssl = true
    con.start {|http| http.request(req)}
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

