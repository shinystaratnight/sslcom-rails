# Represents a domain name or ip address to be secured by a UCC or Multi domain SSL
require 'resolv'

class CertificateName < ApplicationRecord
  belongs_to  :certificate_content
  has_one   :certificate_order, through: :certificate_content
  has_many    :signed_certificates, through: :certificate_content
  has_many    :caa_checks, as: :checkable
  has_many    :ca_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_resend_requests, as: :api_requestable, dependent: :destroy
  has_many    :validated_domain_control_validations, -> { where(workflow_state: "satisfied")},
              class_name: "DomainControlValidation"
  has_many    :last_sent_domain_control_validations, -> { where{email_address !~ 'null'}},
              class_name: "DomainControlValidation"
  has_one :domain_control_validation, -> { order 'created_at' }, class_name: "DomainControlValidation",
              unscoped: true
  has_many    :domain_control_validations, dependent: :destroy do
    def last_sent
      where{email_address !~ 'null'}.last
    end

    def last_emailed
      where{(email_address !~ 'null') & (dcv_method >> [nil,'email'])}.last
    end

    def last_method
      where{dcv_method >> ['http','https','email','cname']}.last
    end

    def validated
      where{workflow_state=="satisfied"}.last
    end
  end
  has_many    :notification_groups_subjects, as: :subjectable
  has_many    :notification_groups, through: :notification_groups_subjects

  attr_accessor :csr

  scope :find_by_domains, ->(domains){includes(:domain_control_validations).where{name>>domains}}
  scope :validated, ->{joins(:domain_control_validations).where{domain_control_validations.workflow_state=="satisfied"}}
  scope :last_domain_control_validation, ->{joins(:domain_control_validations).limit(1)}
  scope :expired_validation, ->{
    joins(:domain_control_validations)
        .where('domain_control_validations.id = (SELECT MAX(domain_control_validations.id) FROM domain_control_validations WHERE domain_control_validations.certificate_name_id = certificate_names.id)')
        .where{(domain_control_validations.responded_at < DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago.to_date)}
  }
  scope :unvalidated, ->{
    satisfied = <<~SQL
    SELECT COUNT(domain_control_validations.id) FROM domain_control_validations
    WHERE certificate_name_id = certificate_names.id AND workflow_state='satisfied'
    SQL
    total = <<~SQL
    SELECT COUNT(domain_control_validations.id) FROM domain_control_validations
    WHERE certificate_name_id = certificate_names.id
    SQL
    where "(#{total}) >= 0 AND (#{satisfied}) = 0"
  }
  scope :sslcom, ->{joins{certificate_content}.where.not certificate_contents: {ca_id: nil}}
  scope :global, -> {where{(certificate_content_id==nil) & (ssl_account_id==nil) & (acme_account_id==nil)}}
  scope :search_domains, lambda {|term|
    term ||= ""
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = { email: nil, name: nil, expired_validation: nil }

    filters.each {|fn, fv|
      term.delete_if {|str| str =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1}
    }

    term = term.empty? ? nil : term.join(" ")

    return nil if [term, *(filters.values)].compact.empty?

    result = self.all
    unless term.blank?
      result = result.where{
        (email =~ "%#{term}%") |
        (name =~ "%#{term}%")
      }
    end

    %w(expired_validation).each do |field|
      query = filters[field.to_sym]
      result = result.expired_validation if query
    end

    result.uniq.order(created_at: :desc)
  }

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
    csr.cname_destination
  end

  def non_wildcard_name(check_type=false)
    check_type && self.certificate_order.certificate.is_single? ?
        CertificateContent.non_wildcard_name(name,true) :
        CertificateContent.non_wildcard_name(name,false)
  end

  # requires csr not be blank
  def dcv_contents
    csr.dcv_contents
  end

  def csr
    @csr || certificate_content.try(:csr)
  end

  def cached_csr_public_key_sha1
    if @csr
      @csr.public_key_sha1
    else
      certificate_content.cached_csr_public_key_sha1
    end
  end

  def cached_csr_public_key_md5
    if @csr
      @csr.public_key_md5
    else
      certificate_content.cached_csr_public_key_md5
    end
  end

  def new_name(new_name)
    @new_name = new_name.downcase if new_name
  end

  def name
    ori_name = read_attribute(:name).downcase
    @new_name ? (@new_name == ori_name ? ori_name : @new_name) : ori_name
  end

  # if the domain has been validated, do not allow changing it's name
  def name=(name)
    dcv=self.domain_control_validations.last
    super unless (dcv and dcv.satisfied?)
  end

  def ca_tag
    csr.ca_tag
  end

  # TODO: all methods check http, https, and cname of protocol is nil
  def dcv_verify(protocol=nil)
    protocol ||= domain_control_validation.try(:dcv_method)
    return nil if protocol=~/email/
    prepend=""
    CertificateName.dcv_verify(protocol: protocol,
                               https_dcv_url: dcv_url(true,prepend, true),
                               http_dcv_url: dcv_url(false,prepend, true),
                               cname_origin: cname_origin(true), 
                               cname_destination: cname_destination,
                               csr: csr,
                               ca_tag: ca_tag)
  end

  def self.dcv_verify(options)
    begin
      Timeout.timeout(Surl::TIMEOUT_DURATION) do
        if options[:protocol]=~/https/
          uri = URI.parse(options[:https_dcv_url])
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Get.new(uri.request_uri)
          r = http.request(request).body
        elsif options[:protocol]=~/cname/
          txt = Resolv::DNS.open do |dns|
            records = dns.getresources(options[:cname_origin], Resolv::DNS::Resource::IN::CNAME)
          end
          return (txt.size > 0) ? (options[:cname_destination].downcase==txt.last.name.to_s.downcase) : false
        else
          r=open(options[:http_dcv_url], "User-Agent" =>
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246",
             redirect: true).read
        end
        return true if !!(r =~ Regexp.new("^#{options[:csr].sha2_hash}") &&
            (options[:ca_tag]=="ssl.com" ? true : r =~ Regexp.new("^#{options[:ca_tag]}")) &&
            ((options[:csr].unique_value.blank? or options[:ignore_unique_value]) ? true : r =~ Regexp.new("^#{options[:csr].unique_value}")))
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
    certificate_order.ca_mdc_statuses.last.domain_status[name]
  end

  def validate_via_cname
    domain_control_validations.create(dcv_method: "cname").satisfy!
  end

  def caa_lookup
    CaaCheck::CAA_COMMAND.call name
  end

  def get_asynch_cache_label
    "#{cache_key}/get_asynch_domains/#{non_wildcard_name}"
  end

  WhoisJob = Struct.new(:dname, :certificate_name) do
    def perform
      dcv=DomainControlValidation.global.find_by_subject(dname)
      if dcv
        standard_addresses = dcv.candidate_addresses
      else
        standard_addresses = DomainControlValidation.email_address_choices(dname)
        begin
          d=::PublicSuffix.parse(dname)
          whois=Whois.whois(ActionDispatch::Http::URL.extract_domain(d.domain, 1)).to_s
          whois_addresses = WhoisLookup.email_addresses(whois.gsub(/^.*?abuse.*?$/i,"")) # remove any line with 'abuse'
          whois_addresses.each do |ad|
            standard_addresses << ad.downcase unless ad =~/abuse.*?@/i
          end unless whois_addresses.blank?
        rescue Exception=>e
          Logger.new(STDOUT).error e.backtrace.inspect
        end
        DomainControlValidation.global.find_or_create_by(subject: dname).update_column(:candidate_addresses,
                                                                                       standard_addresses)
      end
      Rails.cache.write("CertificateName.candidate_email_addresses/#{dname}",standard_addresses,
                        expires_in: DomainControlValidation::EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days)
      cert_names=CertificateName.where("name = ?", "#{dname}")
      cert_names.update_all(updated_at: Time.now)
      cert_names.each{|cn| Rails.cache.delete(cn.get_asynch_cache_label)}
      CertificateContent.where{id >> cert_names.map(&:certificate_content_id)}.update_all(updated_at: Time.now)
      if certificate_name
        dcv=certificate_name.domain_control_validations.last
        dcv.update_column(:candidate_addresses, standard_addresses) if dcv
      end
    end

    def max_attempts
      3
    end

    def max_run_time
      300 # seconds
    end
  end

  def candidate_email_addresses(clear_cache=false)
    Rails.cache.delete("CertificateName.candidate_email_addresses/#{non_wildcard_name}") if clear_cache
    CertificateName.candidate_email_addresses(name,self)
  end

  # certificate_name in the event the domain_control_validations candidate addresses need to be updated
  def self.candidate_email_addresses(name,certificate_name=nil)
    name=CertificateContent.non_wildcard_name(name,false)
    Rails.cache.fetch("CertificateName.candidate_email_addresses/#{name}",
                      expires_in: DomainControlValidation::EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days) do
      Delayed::Job.enqueue WhoisJob.new(name,certificate_name)
      DomainControlValidation.global.find_by_subject(name).try(:candidate_addresses) ||
          DomainControlValidation.email_address_choices(name)
    end
  end

  def self.add_email_address_candidate(dname,email_address)
    Rails.cache.delete("CertificateName.candidate_email_addresses/#{dname}")
    cert_names=CertificateName.where("name = ?", "#{dname}")
    cert_names.update_all(updated_at: Time.now)
    cert_names.each{|cn| Rails.cache.delete(cn.get_asynch_cache_label)}
    CertificateContent.where{id >> cert_names.map(&:certificate_content_id)}.update_all(updated_at: Time.now)
    standard_addresses=CertificateName.candidate_email_addresses(dname)
    standard_addresses << email_address
    DomainControlValidation.global.find_or_create_by(subject: dname.gsub(/\A\*\./, "").downcase).update_column(
        :candidate_addresses, standard_addresses)
  end
end
