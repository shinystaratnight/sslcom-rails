require 'savon'

class EjbcaApi
  def self.connect_ejbca_api
    client = Savon::Client.new(log_level: :debug,
                               log: true,
                               ssl_verify_mode: :none,
                               ssl_cert_file: '/media/windows-share/ejbca.crt',
                               ssl_cert_key_file: '/media/windows-share/ejbca.key',
                               ssl_cert_key_password: 'ejbca',
                               wsdl: "https://62.202.32.68:18443/ejbca/ejbcaws/ejbcaws?wsdl",
                               endpoint: "https://62.202.32.68:18443/ejbca/ejbcaws/ejbcaws")
  end
end


