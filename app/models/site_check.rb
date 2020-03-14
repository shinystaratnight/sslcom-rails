# == Schema Information
#
# Table name: site_checks
#
#  id                    :integer          not null, primary key
#  url                   :text(65535)
#  created_at            :datetime
#  updated_at            :datetime
#  certificate_lookup_id :integer
#
# Indexes
#
#  index_site_checks_on_certificate_lookup_id  (certificate_lookup_id)
#

require 'net/http'
require 'net/https'
require 'open-uri'
require 'timeout'


# A site check is a query from the website to
# query the ssl status of a domain

class SiteCheck < ApplicationRecord
  belongs_to :certificate_lookup

  attr_accessor :verify_trust, :ssl_client, :openssl_connect_result

  validates :url, :presence=>true, :on=>:save

  after_initialize do
    self.lookup
    self.verify_trust ||= true
  end

  before_create :create_certificate_lookup

  COMMAND=->(url, port){%x"echo QUIT | openssl s_client -CApath /etc/ssl/certs/ -showcerts -servername #{url} -verify_hostname #{url} -connect #{url}:#{port}"}

  TIMEOUT_DURATION=10

  def openssl_connect(port=443)
    self.openssl_connect_result=timeout(TIMEOUT_DURATION) do
      COMMAND.call self.url, port
    end
    rescue
  end

  def s_client_issuers
    self.openssl_connect_result ||= openssl_connect
    self.openssl_connect_result.scan(/i\:(.+?)\n/).flatten
  end

  def lookup
    context = OpenSSL::SSL::SSLContext.new
    if self.verify_trust
      #context.verify_depth=5
      context.ca_file="/usr/lib/ssl/certs/ca-certificates.crt"
      context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    Timeout.timeout(10) do
      u,p = url.split ":"
      tcp_client = TCPSocket.new(u, p || 443)
      self.ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
      self.ssl_client.connect
    end
  rescue
    nil
  end

  def result
    self.ssl_client.verify_result
  end

  def certificate
    ssl_client.peer_cert_chain_with_openssl_extension.first unless all_certificates.blank?
  end

  def all_certificates
    ssl_client.peer_cert_chain_with_openssl_extension unless ssl_client.blank?
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

  def create_certificate_lookup
    self.certificate_lookup=
      unless self.certificate.blank?
        serial=self.certificate.serial.to_s
        CertificateLookup.find_or_create_by_serial(serial,
          serial: serial, certificate: self.certificate.to_s,
          common_name: self.certificate.subject.common_name,
          expires_at: self.certificate.not_after)
      end
  end

  def self.days_left(subject,carry_over=false)
    return 0 if subject.blank?
    old_certificate=SiteCheck.new(url: subject, verify_trust: false).certificate
    result=
      if old_certificate && ((old_certificate.not_after.to_date - DateTime.now.to_date).to_i > 0)
        (old_certificate.not_after.to_date - DateTime.now.to_date).to_i
      else
        0
      end
    carry_over && result > 90 ? 90 : result
  end
end
