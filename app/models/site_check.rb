require 'net/http'
require 'net/https'
require 'open-uri'
require 'timeout'

class SiteCheck < ActiveRecord::Base
  belongs_to :certificate_lookup

  attr_accessor :certificate
  attr_accessor :all_certificates
  attr_accessor :ssl_client
  attr_accessor :context
  attr_accessor :result

  validates :url, :presence=>true, :on=>:save

  before_create{|sc|
    sc.lookup
  }

  COMMAND=->(url, port){%x"openssl s_client -connect #{url}:#{port} -CAfile /usr/lib/ssl/certs/ca-certificates.crt"}
  TIMEOUT_DURATION=2

  def openssl_connect(port=443)
    timeout(TIMEOUT_DURATION) do
      COMMAND.call self.url, port
    end
    rescue
  end

  def lookup
    self.context = OpenSSL::SSL::SSLContext.new
    self.context.verify_depth=1
    self.context.ca_file="/usr/lib/ssl/certs/ca-certificates.crt"
    #context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    tcp_client = TCPSocket.new url, 443
    self.ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
    self.ssl_client.connect
    self.result=self.ssl_client.verify_result
    self.certificate=ssl_client.peer_cert_chain_with_openssl_extension.first
    self.all_certificates=ssl_client.peer_cert_chain_with_openssl_extension
    serial=self.certificate.serial.to_s
    unless self.certificate.blank?
      self.certificate_lookup=CertificateLookup.find_or_create_by_serial(serial,
        serial: serial, certificate: self.certificate.to_s,
        common_name: self.certificate.subject.common_name,
        expires_at: self.certificate.not_after)
    end
  end

  def url=(o_url)
    is_uri = o_url =~ /\:\/\//
    write_attribute :url, is_uri ? URI.parse(o_url).host : o_url
  end

  def ou_array(subject)
    s=subject_to_array(subject)
    s.select do |o|
      h=Hash[*o]
      true unless (h["OU"]).blank?
    end.map{|ou|ou[1]}
  end

  def subject_to_array(subject)
    subject.split(/\/(?=[\w\d\.]+\=)/).reject{|o|o.blank?}.map{|o|o.split(/(?<!\\)=/)}
  end

end
