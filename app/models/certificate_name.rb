# frozen_string_literal: true

#
# == Schema Information
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  acme_token             :string(255)
#  caa_passed             :boolean          default(FALSE)
#  email                  :string(255)
#  is_common_name         :boolean
#  name                   :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  acme_account_id        :string(255)
#  certificate_content_id :integer
#  ssl_account_id         :integer
#
# Indexes
#
#  index_certificate_names_on_acme_token              (acme_token)
#  index_certificate_names_on_certificate_content_id  (certificate_content_id)
#  index_certificate_names_on_name                    (name)
#  index_certificate_names_on_ssl_account_id          (ssl_account_id)
#

# Represents a domain name or ip address to be secured by a UCC or Multi domain SSL
require 'resolv'

class CertificateName < ApplicationRecord
  include Pagable

  belongs_to :certificate_content
  belongs_to :ssl_account, class_name: 'SslAccount', foreign_key: 'ssl_account_id'

  has_one :certificate_order, through: :certificate_content
  has_many    :signed_certificates, through: :certificate_content
  has_many    :caa_checks, as: :checkable
  has_many    :ca_certificate_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  has_many    :ca_dcv_resend_requests, as: :api_requestable, dependent: :destroy
  has_many    :validated_domain_control_validations, -> { where(workflow_state: 'satisfied') }, class_name: 'DomainControlValidation'
  has_many    :last_sent_domain_control_validations, -> { where{ email_address !~ 'null' } }, class_name: 'DomainControlValidation'
  has_one :domain_control_validation, -> { order 'created_at' }, class_name: 'DomainControlValidation', unscoped: true
  has_many :domain_control_validations, dependent: :destroy do
    def last_sent
      where{ email_address !~ 'null' }.last
    end

    def last_emailed
      where{ (email_address !~ 'null') & (dcv_method >> [nil, 'email']) }.last
    end

    def last_method
      where{ dcv_method >> %w[http https email cname] }.last
    end

    def validated
      where{ workflow_state == 'satisfied' }.last
    end
  end
  has_many    :notification_groups_subjects, as: :subjectable
  has_many    :notification_groups, through: :notification_groups_subjects

  attr_accessor :csr
  delegate :all_domains_validated?, to: :certificate_content, prefix: false, allow_nil: true

  scope :find_by_domains, ->(domains){ includes(:domain_control_validations).where{ name >> domains } }
  scope :validated, ->{ joins(:domain_control_validations).where{ domain_control_validations.workflow_state == 'satisfied' } }
  scope :having_dvc, -> { joins(:domain_control_validations).group('domain_control_validations.id').having('count(*) > ?', 0) }
  scope :last_domain_control_validation, ->{ joins(:domain_control_validations).limit(1) }
  scope :expired_validation, ->{
    joins(:domain_control_validations)
        .where('domain_control_validations.id = (SELECT MAX(domain_control_validations.id) FROM domain_control_validations WHERE domain_control_validations.certificate_name_id = certificate_names.id)')
        .where{ (domain_control_validations.responded_at < DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago.to_date) }
  scope :last_domain_control_validation, ->{ joins(:domain_control_validations).limit(1) }
  scope :expired_validation, ->{
    joins(:domain_control_validations)
      .where('domain_control_validations.id = (SELECT MAX(domain_control_validations.id) FROM domain_control_validations WHERE domain_control_validations.certificate_name_id = certificate_names.id)')
      .where{ (domain_control_validations.responded_at < DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago.to_date) }
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
  scope :sslcom, ->{ joins{ certificate_content }.where.not certificate_contents: {ca_id: nil} }
  scope :global, -> { where{ (certificate_content_id == nil) & (ssl_account_id == nil) & (acme_account_id == nil) } }
  scope :search_domains, lambda { |term|
    term ||= ''
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = { email: nil, name: nil, expired_validation: nil }

    filters.each { |fn, fv|
      term.delete_if { |str| str =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1 }
    }

    term = term.empty? ? nil : term.join(' ')

    return nil if [term, *filters.values].compact.empty?

    result = self.all
    unless term.blank?
      result = result.where{
        (email =~ "%#{term}%") |
        (name =~ "%#{term}%")
      }
    end

    %w[expired_validation].each do |field|
      query = filters[field.to_sym]
      result = result.expired_validation if query
    end

    result.uniq.order(created_at: :desc)
  }

  after_initialize do
    generate_acme_token if acme_token.blank?
  end

  def is_ip_address?
    name&.index(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/)&.zero?
  end

  def is_server_name?
    name.index(/\./).nil? if name
  end

  def is_fqdn?
    name&.index(/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\z/ix)&.zero? unless is_ip_address? && is_server_name?
  end

  def is_intranet?
    CertificateContent.is_intranet?(name)
  end

  def is_tld?
    CertificateContent.is_tld?(name)
  end

  def top_level_domain
    if is_fqdn?
      name =~ /(?:.*?\.)(.+)/
      $1
    end
  end

  def validation_source
    last_dcv&.dcv_method
  end

  def last_dcv
    (domain_control_validations.last.try(:dcv_method) =~ /https?/) ? domain_control_validations.last : domain_control_validations.last_sent
  end

  def last_dcv_for_comodo_auto_update_dcv
    CertificateName.to_comodo_method(domain_control_validations.last.try(:dcv_method))
  end

  def self.to_comodo_method(dcv_method)
    case dcv_method
      when /https/i, ''
        'HTTPS_CSR_HASH'
      when /http/i, ''
        'HTTP_CSR_HASH'
      when /cname/i
        'CNAME_CSR_HASH'
      when /email/i
        'EMAIL'
    end
  end

  def last_dcv_for_comodo
    case domain_control_validations.last.try(:dcv_method)
      when /https?/i, ''
        'HTTPCSRHASH'
      when /cname/i
        'CNAMECSRHASH'
      else
        domain_control_validations.last_sent.try :email_address
    end
  end

  def dcv_url(secure = false, prepend = '', check_type = false)
    "http#{'s' if secure}://#{prepend + non_wildcard_name(check_type)}/.well-known/pki-validation/#{csr.md5_hash}.txt"
  end

  def cname_origin(check_type = false)
    "#{csr.dns_md5_hash}.#{non_wildcard_name(check_type)}"
  end

  def cname_destination
    csr.cname_destination
  end

  def non_wildcard_name(check_type = false)
    check_type && self.certificate_order.certificate.is_single? ?
        CertificateContent.non_wildcard_name(name, true) :
        CertificateContent.non_wildcard_name(name, false)
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
    dcv = self.domain_control_validations.last
    super unless (dcv and dcv.satisfied?)
  end

  def ca_tag
    csr.ca_tag
  end

  # TODO: all methods check http, https, and cname of protocol is nil
  def dcv_verify(protocol = nil)
    protocol ||= domain_control_validation.try(:dcv_method)
    return nil if protocol =~ /email/
    prepend = ''
    CertificateName.dcv_verify(protocol: protocol,
                               https_dcv_url: dcv_url(true, prepend, true),
                               http_dcv_url: dcv_url(false, prepend, true),
                               cname_origin: cname_origin(true),
                               cname_destination: cname_destination,
                               csr: csr,
                               ca_tag: ca_tag)
  end

  def self.dcv_verify(options)
    begin
      Timeout.timeout(Surl::TIMEOUT_DURATION) do
        if options[:protocol] = ~/https/
          r = CertificateName.https_verify(options[:https_dcv_url])
        elsif options[:protocol] = ~/cname/
          return CertificateName.cname_verify(options[:cname_origin], options[:cname_destination])
        else
          r = CertificateName.http_verify(options[:http_dcv_url])
        end
        return true if !!(r =~ Regexp.new("^#{options[:csr].sha2_hash}") &&
            (options[:ca_tag] == I18n.t('labels.ssl_ca') ? true : r =~ Regexp.new("^#{options[:ca_tag]}")) &&
            (options[:csr].unique_value.blank? || options[:ignore_unique_value]) ? true : r =~ Regexp.new("^#{options[:csr].unique_value}"))
      end
    rescue StandardError => _e
      false
    end
  end

  def self.https_verify(https_dcv_url)
    uri = URI.parse(https_dcv_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request).body
  end

  def self.cname_verify(cname_origin, cname_destination)
    txt = Resolv::DNS.open do |dns|
      records = dns.getresources(cname_origin, Resolv::DNS::Resource::IN::CNAME)
    end
    txt.size.positive? ? cname_destination.downcase == txt.last.name.to_s.downcase : false
  end

  def self.http_verify(http_dcv_url)
    uri = URI.parse(http_dcv_url)
    response = uri.open('User-Agent' => I18n.t('users_agent.chrome'), redirect: true)
    response.read
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
    domain_control_validations.create(dcv_method: 'cname').satisfy!
  end

  def caa_lookup
    CaaCheck::CAA_COMMAND.call name
  end

  def get_asynch_cache_label
    "#{cache_key}/get_asynch_domains/#{non_wildcard_name}"
  end

  def candidate_email_addresses(clear_cache=false)
    Rails.cache.delete("CertificateName.candidate_email_addresses/#{non_wildcard_name}") if clear_cache
    CertificateName.candidate_email_addresses(name, self)
  end

  # certificate_name in the event the domain_control_validations candidate addresses need to be updated
  def self.candidate_email_addresses(name, certificate_name=nil)
    name = CertificateContent.non_wildcard_name(name, false)
    Rails.cache.fetch("CertificateName.candidate_email_addresses/#{name}", expires_in: DomainControlValidation::EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days) do
      Delayed::Job.enqueue WhoIsJob.new(name, certificate_name)
      DomainControlValidation.global.find_by_subject(name).try(:candidate_addresses) || DomainControlValidation.email_address_choices(name)
    end
  end

  def self.add_email_address_candidate(dname, email_address)
    Rails.cache.delete("CertificateName.candidate_email_addresses/#{dname}")
    cert_names = CertificateName.where('name = ?', "#{dname}")
    cert_names.update_all(updated_at: Time.now)
    cert_names.each{ |cn| Rails.cache.delete(cn.get_asynch_cache_label) }
    CertificateContent.where{ id >> cert_names.map(&:certificate_content_id) }.update_all(updated_at: Time.now)
    standard_addresses = CertificateName.candidate_email_addresses(dname)
    standard_addresses << email_address
    DomainControlValidation.global.find_or_create_by(subject: dname.gsub(/\A\*\./, '').downcase).update_column(:candidate_addresses, standard_addresses)
  end

  def generate_acme_token
    self.acme_token = loop do
      random_token = SecureRandom.urlsafe_base64(96, false)
      break random_token unless CertificateName.exists?(acme_token: random_token)
    end
    save if persisted?
  end
end
