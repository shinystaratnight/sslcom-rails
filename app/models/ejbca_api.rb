require 'savon'

class EjbcaApi
  def self.connect_ejbca_api
    client = Savon::Client.new(log_level: :debug,
                               log: true,
                               ssl_cert_file: '/vagrant/config/ssl/leoca.crt',
                               ssl_ca_cert_file: '/vagrant/config/ssl/leocacert.crt',
                               ssl_cert_key_file: '/vagrant/config/ssl/leoca.key',
                               ssl_cert_key_password: '1234',
                               wsdl: "https://192.168.5.17:8443/ejbca/ejbcaws/ejbcaws?wsdl",
                               endpoint: "https://192.168.5.17:8443/ejbca/ejbcaws/ejbcaws")
  end
end


