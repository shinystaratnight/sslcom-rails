class CertificateContent < ActiveRecord::Base
  belongs_to  :certificate_order
  belongs_to  :server_software
  has_one     :csr
  has_one     :registrant, :as => :contactable
  has_many    :certificate_contacts, :as => :contactable

#  attr_accessible :certificate_contacts_attributes

  #before_update :delete_duplicate_contacts

  accepts_nested_attributes_for :certificate_contacts, :allow_destroy => true
  accepts_nested_attributes_for :registrant, :allow_destroy => false

  SIGNING_REQUEST_REGEX = /\A[\w\-\/\s\n\+=]+\Z/
  MIN_KEY_SIZE = 2048

  ADMINISTRATIVE_ROLE = 'administrative'
  CONTACT_ROLES = %w(administrative billing technical validation)

  RESELLER_FIELDS_TO_COPY = %w(first_name last_name
   po_box address1 address2 address3 city state postal_code email phone ext fax)

  #SSL.com=>Comodo
  COMODO_SERVER_SOFTWARE_MAPPINGS = {
      1=>-1, 2=>1, 3=>2, 4=>3, 5=>4, 6=>33, 7=>34, 8=>5,
      9=>6, 10=>29, 11=>32, 12=>7, 13=>8, 14=>9, 15=>0,
      16=>11, 17=>12, 18=>13, 19=>14, 20=>35, 21=>15,
      22=>16, 23=>17, 24=>18, 25=>30, 26=>19, 27=>20, 28=>21,
      29=>22, 30=>23, 31=>24, 32=>25, 33=>26, 34=>27, 35=>31, 36=>28}

  serialize :domains

  unless MIGRATING_FROM_LEGACY
    validates_presence_of :server_software_id, :signing_request,
      :if => :certificate_order_has_csr
    validates_format_of :signing_request, :with=>SIGNING_REQUEST_REGEX,
      :message=> 'contains invalid characters.',
      :if => :certificate_order_has_csr
    validate :domains_validation, :if=>"certificate_order.certificate.is_ucc?"
    validate :csr_validation, :if=>"csr"
  end

  attr_accessor  :additional_domains #used to html format results to page

  preference  :reprocessing, default: false

  include Workflow
  workflow do
    state :new do
      event :submit_csr, :transitions_to => :csr_submitted
      event :cancel, :transitions_to => :canceled
    end

    state :csr_submitted do
      event :provide_info, :transitions_to => :info_provided
      event :reprocess, :transitions_to => :reprocess_requested
      event :cancel, :transitions_to => :canceled
    end

    state :info_provided do
      event :provide_contacts, :transitions_to => :contacts_provided
      event :cancel, :transitions_to => :canceled
    end

    state :contacts_provided do
      event :pend_validation, :transitions_to => :pending_validation do
        certificate_order.apply_for_certificate if csr.ca_certificate_requests.blank?
      end
      event :cancel, :transitions_to => :canceled
    end

    state :pending_validation do
      event :validate, :transitions_to => :validated do
        self.preferred_reprocessing = false if self.preferred_reprocessing?
      end
      event :cancel, :transitions_to => :canceled
    end

    state :validated do
      event :pend_validation, :transitions_to => :pending_validation
      event :issue, :transitions_to => :issued
      event :cancel, :transitions_to => :canceled
    end

    state :issued do
      event :reprocess, :transitions_to => :csr_submitted
      event :cancel, :transitions_to => :canceled
      event :revoke, :transitions_to => :revoked
    end

    state :canceled

    state :revoked
  end

  def domains=(domains)
    unless domains.blank?
      domains = domains.split(/\s+/).uniq.reject{|d|d.blank?}
    end
    write_attribute(:domains, domains)
  end

  def additional_domains=(html_domains)
    self.domains=html_domains
  end

  def additional_domains
    domains.join("\ ") unless domains.blank?
  end

  def signing_request=(signing_request)
    write_attribute(:signing_request, signing_request)
    return unless (signing_request=~SIGNING_REQUEST_REGEX)==0
    self.csr
    self.build_csr(:body=>signing_request)
    unless self.csr.common_name.blank?
      self.csr.save
    end
  end

  def migrated_from
    v=V2MigrationProgress.find_by_migratable(self, :all)
    v.map(&:source_obj) if v
  end

  CONTACT_ROLES.each do |role|
    define_method("#{role}_contacts") do
      certificate_contacts(true).select{|c|c.has_role? role}
    end

    define_method("#{role}_contact") do
      send("#{role}_contacts").last
    end
  end

  def expired?
    csr.signed_certificate.expired? if csr.try(:signed_certificate)
  end

  def comodo_server_software_id
    COMODO_SERVER_SOFTWARE_MAPPINGS[server_software.id]
  end

  def has_all_contacts?
    CONTACT_ROLES.all? do |role|
      send "#{role}_contact"
    end
  end

  private

  def domains_validation
    is_wildcard = certificate_order.certificate.allow_wildcard_ucc?
    invalid_chars_msg = "have invalid characters. Only the following characters
      are allowed [A-Za-z0-9.-#{'*' if is_wildcard}]"
    unless domains.blank?
      errors.add(:additional_domains, invalid_chars_msg) unless domains.reject{|domain|
        domain_validation_regex(is_wildcard, domain)}.empty?
    end
  end

  def csr_validation
    is_wildcard = certificate_order.certificate.is_wildcard?
    invalid_chars_msg = "has invalid characters. Only the following characters
      are allowed [A-Za-z0-9.-#{'*' if is_wildcard}]"
    if csr.common_name.blank?
      errors.add(:signing_request, 'is invalid and cannot be parsed')
    else
      asterisk_found = (csr.common_name=~/^\*\./)==0
      if is_wildcard && !asterisk_found
        errors.add(:signing_request, "is wildcard certificate order,
          so it must begin with *.")
      elsif !is_wildcard && asterisk_found
        errors.add(:signing_request,
          "cannot begin with *. since it is not a wildcard")
      end
      errors.add(:signing_request, invalid_chars_msg) unless
        domain_validation_regex(is_wildcard, csr.common_name)
      errors.add(:signing_request, "must have a 2048 bit key size.
        Please submit a new ssl.com certificate signing request with the proper key size.") if
          csr.strength != MIN_KEY_SIZE
    end
  end

  def domain_validation_regex(is_wildcard, domain)
    invalid_chars = "[^\\s\\n\\w\\.\\-#{'\\*' if is_wildcard}]"
    domain.index(Regexp.new(invalid_chars))==nil and
    domain.index(/\.\.+/)==nil and domain.index(/^\./)==nil and
    domain.index(/[^\w]$/)==nil and domain.index(/^[^\w\*]/)==nil and
      is_wildcard ? (domain.index(/(\w)\*/)==nil and
        domain.index(/(\*)[^\.]/)==nil) : true
  end

  def certificate_order_has_csr
    certificate_order.has_csr=='true' || certificate_order.has_csr==true
  end

  def delete_duplicate_contacts
    CONTACT_ROLES.each do |role|
      contacts = send "#{role}_contacts"
      if contacts.count > 1
        contacts.shift
        contacts.each do |c|
          c.destroy
        end
      end
    end
    true
  end
end
