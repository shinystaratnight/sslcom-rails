require 'net/http'
require 'net/https'
require 'open-uri'

class SiteCheck < ActiveRecord::Base
  belongs_to :certificate_lookup

  attr_accessor :certificate

  validates :url, :presence=>true, :on=>:save

  before_create{|sc|
    sc.lookup
  }

  def lookup
    context = OpenSSL::SSL::SSLContext.new
    tcp_client = TCPSocket.new url, 443
    ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
    ssl_client.connect
    self.certificate=ssl_client.peer_cert_chain_with_openssl_extension.first
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
