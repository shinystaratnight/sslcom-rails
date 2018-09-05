require 'public_suffix'

class DomainControlValidation < ActiveRecord::Base
  has_many :ca_dcv_requests, as: :api_requestable, dependent: :destroy
  belongs_to :csr, touch: true # only for single domain certs
  belongs_to :csr_unique_value
  belongs_to :certificate_name, touch: true  # only for UCC or multi domain certs
  serialize :candidate_addresses

  # validate  :email_address_check, unless: lambda{|r| r.email_address.blank?}

  IS_INVALID  = "is an invalid email address choice"
  FAILURE_ACTION = %w(ignore reject)
  AUTHORITY_EMAIL_ADDRESSES = %w(admin@ administrator@ webmaster@ hostmaster@ postmaster@)

  include Workflow
  workflow do
    state :new do
      event :send_dcv, :transitions_to => :sent_dcv
      event :hashing, :transitions_to => :hashed
      event :satisfy, :transitions_to => :satisfied
    end

    state :hashed do
      event :satisfy, :transitions_to => :satisfied
    end

    state :sent_dcv do
      event :satisfy, :transitions_to => :satisfied

      on_entry do
        self.update_attribute :sent_at, DateTime.now
      end
    end

    state :satisfied do
      on_entry do
        self.update_attribute :responded_at, DateTime.now
      end
    end
  end

  def email_address_check
    errors.add(:email_address, "'#{email_address}' "+IS_INVALID) unless
      candidate_addresses.include?(email_address)
  end

  def send_to(address)
    update_attributes email_address: address, sent_at: DateTime.now, dcv_method: "email"
    if csr.sent_success
      ComodoApi.auto_update_dcv(dcv: self)
      co=csr.certificate_content.certificate_order
      co.valid_recipients_list.each do |c|
        OrderNotifier.dcv_sent(c, co, self).deliver!
      end
    end
  end

  def hash_satisfied(http_or_s)
    satisfy! unless satisfied?
    update_attributes sent_at: DateTime.now, dcv_method: http_or_s
  end

  # the 24 hour limit no longer applies, but will keep this in case we need it again
  #def is_eligible_to_send?
  #  !email_address.blank? && updated_at > 24.hours.ago && !satisfied?
  #end

  def is_eligible_to_resend?
    !email_address.blank? && !satisfied?
  end
  alias :is_eligible_to_send? :is_eligible_to_resend?

  def method_for_api(options={http_csr_hash: "http_csr_hash", https_csr_hash: "https_csr_hash",
                              cname_csr_hash: "cname_csr_hash", email: self.email_address})
    case dcv_method
      when "http", "http_csr_hash"
        options[:http_csr_hash]
      when "https", "https_csr_hash"
        options[:https_csr_hash]
      when "cname", "cname_csr_hash"
        options[:cname_csr_hash]
      when "email"
        options[:email]
    end
  end

  def verify_http_csr_hash
    certificate_name.dcv_verified?
  end

  def email_address_choices
    name = (csr.blank? ? certificate_name.name : csr.common_name)
    DomainControlValidation.email_address_choices(name)
  end

  def self.email_address_choices(name)
    Rails.cache.fetch("email_address_choices/#{name}", expires_in: 30.days) do
      return [] unless ::PublicSuffix.valid?(name.downcase)
      d=::PublicSuffix.parse(name.downcase)
      subdomains = d.trd ? d.trd.split(".") : []
      subdomains.shift if subdomains[0]=="*" #remove wildcard
      [].tap {|s|
        0.upto(subdomains.count) do |i|
          s << (subdomains.slice(0,i)<<d.domain).join(".")
        end
      }.map do |e|
        AUTHORITY_EMAIL_ADDRESSES.map do |ae|
          ae+e
        end
      end.flatten
    end
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

  def friendly_action

  end

  def action_performed
    "#{method_for_api({http_csr_hash: "scanning for #{certificate_name.dcv_url}",
                       https_csr_hash: "scanning for #{certificate_name.dcv_url}",
                       cname_csr_hash: "scanning for CNAME: #{certificate_name.cname_origin} -> #{certificate_name.cname_destination}",
                       email: "sent validation to #{self.email_address}"})}"
  end

end
