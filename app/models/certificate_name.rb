# Represents a domain name or ip address to be secured by a UCC or Multi domain SSL
require 'resolv'

class CertificateName < ActiveRecord::Base
  belongs_to  :certificate_content
  has_many    :signed_certificates, through: :certificate_content
  has_many    :caa_checks, as: :checkable
  has_many    :ca_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_resend_requests, as: :api_requestable, dependent: :destroy
  has_many    :domain_control_validations, dependent: :destroy do
    def last_sent
      where{email_address !~ 'null'}.last
    end

    def last_emailed
      where{(email_address !~ 'null') & (dcv_method >> [nil,'email'])}.last
    end

    def last_method
      where{dcv_method >> ['http','https','email']}.last
    end
  end
  has_many    :notification_groups_subjects, as: :subjectable
  has_many    :notification_groups, through: :notification_groups_subjects

  attr_accessor :csr

  scope :find_by_domains, ->(domains){includes(:domain_control_validations).where{name>>domains}}

  #will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  def is_ip_address?
    name.index(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/)==0 if name
  end

  def is_server_name?
    name.index(/\./)==nil if name
  end

  def is_fqdn?
    unless is_ip_address? && is_server_name?
      name.index(/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix)==0 if name
    end
  end

  def is_intranet?
    CertificateContent.is_intranet?(name)
  end

  def is_tld?
    CertificateContent.is_tld?(name)
  end

  def top_level_domain
    if is_fqdn?
      name=~(/(?:.*?\.)(.+)/)
      $1
    end
  end

  def last_dcv
    (domain_control_validations.last.try(:dcv_method)=~/https?/) ?
        domain_control_validations.last : domain_control_validations.last_sent
  end

  def last_dcv_for_comodo_auto_update_dcv
    CertificateName.to_comodo_method(domain_control_validations.last.try(:dcv_method))
  end

  def self.to_comodo_method(dcv_method)
    case dcv_method
      when /https/i, ""
        "HTTPS_CSR_HASH"
      when /http/i, ""
        "HTTP_CSR_HASH"
      when /cname/i
        "CNAME_CSR_HASH"
      when /email/i
        "EMAIL"
    end
  end

  def last_dcv_for_comodo
    case domain_control_validations.last.try(:dcv_method)
      when /https?/i, ""
        "HTTPCSRHASH"
      when /cname/i
        "CNAMECSRHASH"
      else
        domain_control_validations.last_sent.try :email_address
    end
  end

  def dcv_url(secure=false, prepend="", check_type=false)
    "http#{'s' if secure}://#{prepend+non_wildcard_name(check_type)}/.well-known/pki-validation/#{csr.md5_hash}.txt"
  end

  def cname_origin(check_type=false)
    "#{csr.dns_md5_hash}.#{non_wildcard_name(check_type)}"
  end

  def cname_destination
    "#{csr.dns_sha2_hash}.comodoca.com"
  end

  def non_wildcard_name(check_type=false)
    check_type && self.certificate_content.certificate_order.certificate.is_single? ?
        name.gsub(/\A\*\./, "").downcase.gsub("www.", "") : name.gsub(/\A\*\./, "").downcase
  end

  def dcv_contents
    "#{csr.sha2_hash}\ncomodoca.com#{"\n#{csr.unique_value}" unless csr.unique_value.blank?}"
  end

  def csr
    @csr || certificate_content.csr
  end

  def new_name(new_name)
    @new_name = new_name.downcase if new_name
  end

  def name
    ori_name = read_attribute(:name).downcase
    @new_name ? (@new_name == ori_name ? ori_name : @new_name) : ori_name
  end

  def dcv_verified?(options={})
    # if blank then try both
    if options[:http_or_s].blank?
      http_or_s = "http"
      retries=2
    else
      http_or_s = options[:http_or_s] # either 'http' or 'https'
      retries=1
    end
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        if retries<2
          http_or_s = "https" if options[:http_or_s].blank?
          uri = URI.parse(dcv_url(true))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          r = http.request(request).body
        else
          r=open(dcv_url).read
        end
        return http_or_s if !!(r =~ Regexp.new("^#{csr.sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
            (csr.unique_value.blank? ? true : r =~ Regexp.new("^#{csr.unique_value}")))
      end
    rescue Timeout::Error, OpenURI::HTTPError, RuntimeError
      retries-=1
      if retries==0
        return false
      else
        retry
      end
    rescue Exception=>e
      return false
    end
  end

  def dcv_verify(protocol)
    prepend=""
    begin
      Timeout.timeout(Surl::TIMEOUT_DURATION) do
        if protocol=="https"
          uri = URI.parse(dcv_url(true,prepend, true))
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          r = http.request(request).body
        elsif protocol=="cname"
          txt = Resolv::DNS.open do |dns|
            records = dns.getresources(cname_origin(true), Resolv::DNS::Resource::IN::CNAME)
          end
          return (txt.size > 0) ? (cname_destination==txt.last.name.to_s) : false
        else
          r=open(dcv_url(false,prepend, true), redirect: false).read
        end
        return "true" if !!(r =~ Regexp.new("^#{csr.sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
            (csr.unique_value.blank? ? true : r =~ Regexp.new("^#{csr.unique_value}")))
      end
    rescue Exception=>e
      return "false"
    end
  end

  def fetch_public_site
    begin
      timeout(Surl::TIMEOUT_DURATION) do
        r=open("https://"+non_wildcard_name).read unless is_intranet?
        !!(r =~ Regexp.new("^#{csr.sha2_hash}") && r =~ Regexp.new("^comodoca.com") &&
            (csr.unique_value.blank? ? true : r =~ Regexp.new("^#{csr.unique_value}")))
      end
    rescue Exception=>e
      return false
    end
  end

  def whois_lookup
    if whois_lookups.empty?
      whois_lookups.create
    else
      whois_lookups.last
    end
  end

  def update_whois_lookup
    whois_lookups.create
  end

  def ca_validation
    certificate_content.certificate_order.ca_mdc_statuses.last.domain_status[name]
  end

  def caa_lookup
    CaaCheck::CAA_COMMAND.call name
  end

end
