# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_names
#
#  id                     :integer          not null, primary key
#  acme_token             :string(255)
#  caa_passed             :boolean          default("0")
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
  include Concerns::CertificateName::Association
  include Concerns::CertificateName::Scope
  include Concerns::CertificateName::Verification

  after_initialize :generate_acme_token, if: -> { acme_token.nil? }

  def self.search_domains(term)
    matches = ransack(name_cont: term, email_cont: term, m: 'or')
    matches.result
  end

  # scope :search_domains, lambda { |term|
  #   term ||= ''
  #   term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
  #   filters = { email: nil, name: nil, expired_validation: nil }
  #   filters.each do |fn, _fv|
  #     term.delete_if do |str|
  #       str =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?")
  #       filters[fn] ||= $1
  #       $1
  #     end
  #   end
  #   term = term.empty? ? nil : term.join(' ')
  #   return nil if [term, *filters.values].compact.empty?
  #   result = all
  #   unless term.blank?
  #     result = result.where do
  #       (email =~ "%#{term}%") | (name =~ "%#{term}%")
  #     end
  #   end
  #   %w[expired_validation].each do |field|
  #     query = filters[field.to_sym]
  #     result = result.expired_validation if query
  #   end
  #   result.uniq.order(created_at: :desc)
  # }

  def is_ip_address?
    name&.index(/\A(?:[0-9]{1,3}\.){3}[0-9]{1,3}\z/)&.zero?
  end

  def is_server_name?
    name&.index(/\./).nil?
  end

  def is_fqdn?
    name&.index(%r{\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?\z}ix)&.zero? unless is_ip_address? && is_server_name?
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
    domain_control_validations.last.try(:dcv_method) =~ /https?/ ? domain_control_validations.last : domain_control_validations.last_sent
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
    remove_www = check_type && certificate_order&.certificate&.is_single? ? true : false
    CertificateContent.non_wildcard_name(name, remove_www)
  end

  def dcv_contents
    csr&.dcv_contents
  end

  def csr
    @csr ||= certificate_content&.csr
  end

  def cached_csr_public_key_sha1
    csr&.public_key_sha1 || certificate_content&.cached_csr_public_key_sha1
  end

  def cached_csr_public_key_md5
    csr&.public_key_md5 || certificate_content&.cached_csr_public_key_md5
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
    dcv = domain_control_validations.last
    super unless dcv&.satisfied?
  end

  def ca_tag
    csr&.ca_tag
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

  def candidate_email_addresses(clear_cache = false)
    Rails.cache.delete("CertificateName.candidate_email_addresses/#{non_wildcard_name}") if clear_cache
    CertificateName.candidate_email_addresses(name, self)
  end

  # certificate_name in the event the domain_control_validations candidate addresses need to be updated
  def self.candidate_email_addresses(name, certificate_name = nil)
    name = CertificateContent.non_wildcard_name(name, false)
    Rails.cache.fetch("CertificateName.candidate_email_addresses/#{name}", expires_in: DomainControlValidation::EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days) do
      Delayed::Job.enqueue WhoIsJob.new(name, certificate_name)
      DomainControlValidation.global.find_by_subject(name).try(:candidate_addresses) || DomainControlValidation.email_address_choices(name)
    end
  end

  def self.add_email_address_candidate(dname, email_address)
    Rails.cache.delete("CertificateName.candidate_email_addresses/#{dname}")
    cert_names = CertificateName.where('name = ?', dname.to_s)
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
