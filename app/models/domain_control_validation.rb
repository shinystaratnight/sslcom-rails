# frozen_string_literal: true

# == Schema Information
#
# Table name: domain_control_validations
#
#  id                         :integer          not null, primary key
#  address_to_find_identifier :string(255)
#  candidate_addresses        :text(65535)
#  dcv_method                 :string(255)
#  email_address              :string(255)
#  failure_action             :string(255)
#  identifier                 :string(255)
#  identifier_found           :boolean
#  responded_at               :datetime
#  sent_at                    :datetime
#  subject                    :string(255)
#  validation_compliance_date :datetime
#  workflow_state             :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  certificate_name_id        :integer
#  csr_id                     :integer
#  csr_unique_value_id        :integer
#  validation_compliance_id   :integer
#
# Indexes
#
#  index_domain_control_validations_on_3_cols                    (certificate_name_id,email_address,dcv_method)
#  index_domain_control_validations_on_3_cols(2)                 (csr_id,email_address,dcv_method)
#  index_domain_control_validations_on_certificate_name_id       (certificate_name_id)
#  index_domain_control_validations_on_csr_id                    (csr_id)
#  index_domain_control_validations_on_csr_unique_value_id       (csr_unique_value_id)
#  index_domain_control_validations_on_id_csr_id                 (id,csr_id)
#  index_domain_control_validations_on_subject                   (subject)
#  index_domain_control_validations_on_validation_compliance_id  (validation_compliance_id)
#  index_domain_control_validations_on_workflow_state            (workflow_state)
#

require 'public_suffix'

class DomainControlValidation < ApplicationRecord
  include Workflow

  has_many    :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to  :csr, touch: true # only for single domain certs
  belongs_to  :csr_unique_value
  belongs_to  :certificate_name, touch: true # only for UCC or multi domain certs
  delegate    :certificate_content, to: :csr
  serialize   :candidate_addresses
  belongs_to  :validation_compliance

  IS_INVALID = 'is an invalid email address choice'
  FAILURE_ACTION = %w[ignore reject].freeze
  AUTHORITY_EMAIL_ADDRESSES = %w[admin@ administrator@ webmaster@ hostmaster@ postmaster@].freeze
  MAX_DURATION_DAYS = { email: 820 }.freeze
  EMAIL_CHOICE_CACHE_EXPIRES_DAYS = 1

  default_scope{ order('domain_control_validations.created_at asc') }
  scope :global, -> { where{ (certificate_name_id == nil) & (csr_id == nil) } }
  scope :whois_threshold, -> { where(updated_at: 1.hour.ago..DateTime.now) }
  scope :satisfied, -> { where(workflow_state: 'satisfied') }

  after_initialize do
    self.identifier ||= DomainControlValidation.generate_identifier
  end

  workflow do
    state :new do
      event :send_dcv, transitions_to: :sent_dcv
      event :hashing, transitions_to: :hashed
      event :satisfy, transitions_to: :satisfied
    end

    state :hashed do
      event :satisfy, transitions_to: :satisfied
    end

    state :sent_dcv do
      event :satisfy, transitions_to: :satisfied

      on_entry do
        update_attribute :sent_at, DateTime.now
      end
    end

    state :satisfied do
      on_entry do
        hash_satisfied unless dcv_method =~ /email/
        self.validation_compliance_id =
          case dcv_method
          when /email/
            2
          when /http/
            6
          when /cname/
            7
          end
        self.identifier_found = true
        self.responded_at = DateTime.now
        save
      end
    end

    state :failed
  end

  def self.generate_identifier
    (SecureRandom.hex(8) + Time.now.to_i.to_s(32))[0..19]
  end

  def email_address_check
    errors.add(:email_address, "'#{email_address}' " + IS_INVALID) unless DomainControlValidation.approved_email_address? candidate_addresses, email_address
  end

  # use for notifying comodo order customers a dcv is on the way from Comodo
  def send_to(address)
    update_attributes email_address: address, sent_at: DateTime.now, dcv_method: 'email'
    if csr.sent_success
      ComodoApi.auto_update_dcv(dcv: self)
      co = csr.certificate_content.certificate_order
      co.valid_recipients_list.each do |c|
        OrderNotifier.dcv_sent(c, co, self).deliver!
      end
    end
  end

  # assume this belongs to a certificate_name which belongs to an ssl_account
  def hash_satisfied
    prepend = ''
    self.identifier, self.address_to_find_identifier = certificate_name.blank? ? [false, false] :
    case dcv_method
    when /https/
      ["#{certificate_name.csr.sha2_hash}\n#{certificate_name.ca_tag}#{"\n#{certificate_name.csr.unique_value}" unless certificate_name.csr.unique_value.blank?}", certificate_name.dcv_url(true, prepend, true)]
    when /http/
      ["#{certificate_name.csr.sha2_hash}\n#{certificate_name.ca_tag}#{"\n#{certificate_name.csr.unique_value}" unless certificate_name.csr.unique_value.blank?}", certificate_name.dcv_url(false, prepend, true)]
    when /cname/
      [certificate_name.cname_destination, certificate_name.cname_origin(true)]
    end
  end

  # the 24 hour limit no longer applies, but will keep this in case we need it again
  # def is_eligible_to_send?
  #  !email_address.blank? && updated_at > 24.hours.ago && !satisfied?
  # end

  def is_eligible_to_resend?
    !email_address.blank? && !satisfied?
  end
  alias is_eligible_to_send? is_eligible_to_resend?

  def method_for_api(options = { http_csr_hash: 'http_csr_hash',
                                 https_csr_hash: 'https_csr_hash',
                                 cname_csr_hash: 'cname_csr_hash',
                                 email: email_address })
    case dcv_method
    when 'http', 'http_csr_hash'
      options[:http_csr_hash]
    when 'https', 'https_csr_hash'
      options[:https_csr_hash]
    when 'cname', 'cname_csr_hash'
      options[:cname_csr_hash]
    when 'email'
      options[:email]
    end
  end

  def self.ssl_account(domain)
    SslAccount.unscoped
              .joins{ certificate_names.domain_control_validations }
              .joins{ certificate_contents.certificate_names.domain_control_validations }
              .where{ (certificate_names.domain_control_validations.subject =~ domain) || (certificate_contents.certificate_names.domain_control_validations.subject =~ domain) }
  end

  def ssl_account
    SslAccount.unscoped.joins{ domains.domain_control_validations.outer }.where(domain_control_validations: { id: id })
  end

  # this will find multi-level subdomains from a more root level domain
  def self.satisfied_validation(ssl_account, domain, public_key_sha1 = nil)
    name = domain.downcase
    name = ('%' + name[1..-1]) if name[0] == '*' # wildcard
    DomainControlValidation
      .joins(:certificate_name)
      .where{ (identifier_found == 1) & (certificate_name.name =~ name.to_s) & (certificate_name_id >> [ssl_account.all_certificate_names(name, 'validated').pluck(:id)]) }.each do |dcv|
        return dcv if dcv.validated?(name, public_key_sha1)
      end
  end

  def self.validated?(ssl_account, domain, public_key_sha1 = nil)
    satisfied_validation(ssl_account, domain, public_key_sha1).blank? ? false : true
  end

  def cached_csr_public_key_sha1
    Rails.cache.fetch("#{cache_key}/cached_csr_public_key_sha1") do
      csr.public_key_sha1
    end
  end

  def cached_csr_public_key_md5
    Rails.cache.fetch("#{cache_key}/cached_csr_public_key_md5") do
      csr.public_key_md5
    end
  end

  # is this dcv validated?
  # domain - against a domain that may or many not be satisfied by this validation
  # public_key_sha1 - against a csr
  def validated?(domain = nil, public_key_sha1 = nil)
    satisfied = ->(public_key_sha1){
      cert_req = (csr || certificate_name.csr).try(:public_key_sha1) if public_key_sha1
      identifier_found && !responded_at.blank? && responded_at > DomainControlValidation::MAX_DURATION_DAYS[:email].days.ago && (!email_address.blank? || (public_key_sha1 ? cert_req.try(:downcase) == public_key_sha1.downcase : true))
    }
    (domain ? DomainControlValidation.domain_in_subdomains?(domain, certificate_name.name) : true) && satisfied.call(public_key_sha1)
  end

  # this determines if a domain validation will satisfy another domain validation based on 2nd level subdomains and wildcards
  # BE VERY CAREFUL as this drives validation for the entire platform including Web and API
  def self.domain_in_subdomains?(subject, compare_with)
    subject = subject[2..-1] if subject =~ /\A\*\./
    compare_with = compare_with[2..-1] if compare_with =~ /\A\*\./
    if ::PublicSuffix.valid?(subject, default_rule: nil) && ::PublicSuffix.valid?(compare_with, default_rule: nil)
      d = ::PublicSuffix.parse(compare_with)
      compare_with_subdomains = d.trd ? d.trd.split('.').reverse : []
      0.upto(compare_with_subdomains.count) do |i|
        return true if (compare_with_subdomains.slice(0, i).reverse << d.domain).join('.') == subject
      end
    end
    false
  end

  def verify_http_csr_hash
    certificate_name.dcv_verify(dcv_method)
  end

  def email_address_choices
    name = (
    if csr.blank?
      certificate_name_id.nil? ? subject : certificate_name.name
    else
      csr.common_name
    end)
    DomainControlValidation.email_address_choices(name)
  end

  def self.email_address_choices(name)
    name = CertificateContent.non_wildcard_name(name)
    Rails.cache.fetch("email_address_choices/#{name}", expires_in: EMAIL_CHOICE_CACHE_EXPIRES_DAYS.days) do
      return [] unless DomainNameValidator.valid?(name, false)

      d = ::PublicSuffix.parse(name.downcase)
      subdomains = d.trd ? d.trd.split('.') : []
      subdomains.shift if subdomains[0] == '*' # remove wildcard
      [].tap do |s|
        0.upto(subdomains.count) do |i|
          s << if i.zero?
                 d.domain
               else
                 (subdomains.slice(-i, subdomains.count) << d.domain).join('.')
               end
        end
      end.map do |e|
        AUTHORITY_EMAIL_ADDRESSES.map do |ae|
          ae + e
        end
      end.flatten
    end
  end

  def self.approved_email_address?(choices, selection)
    choices.include? selection
  end

  def comodo_email_address_choices
    write_attribute(:candidate_addresses, ComodoApi.domain_control_email_choices(certificate_name.name).email_address_choices)
    save(validate: false)
  end

  def candidate_addresses
    if read_attribute(:candidate_addresses).blank?
      # delay.comodo_email_address_choices
      email_address_choices
    else
      read_attribute(:candidate_addresses)
    end
  end

  def friendly_action; end

  def action_performed
    "#{method_for_api(http_csr_hash: "scanning for #{certificate_name.dcv_url}",
                      https_csr_hash: "scanning for #{certificate_name.dcv_url}",
                      cname_csr_hash: "scanning for CNAME: #{certificate_name.cname_origin} -> #{certificate_name.cname_destination}",
                      email: "sent validation to #{email_address}")}"
  end

  def self.icann_contacts
    @icann_contacts ||= I18n.t(:contacts, scope: :icann)
  end
end
