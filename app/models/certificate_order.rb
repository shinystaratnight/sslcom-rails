class CertificateOrder < ActiveRecord::Base
  include V2MigrationProgressAddon
  #using_access_control
  acts_as_sellable :cents => :amount, :currency => false
  belongs_to  :ssl_account
  belongs_to  :validation
  belongs_to  :site_seal
  belongs_to  :parent, class_name: 'CertificateOrder', :foreign_key=>:renewal_id
  has_one     :renewal, class_name: 'CertificateOrder', :foreign_key=>:renewal_id,
    :dependent=>:destroy
  has_many    :certificate_contents, :dependent => :destroy
  has_many    :csrs, :through=>:certificate_contents, :dependent => :destroy
  has_many    :sub_order_items, :as => :sub_itemable, :dependent => :destroy
  has_many    :orders, :through => :line_items, :include => :stored_preferences
  has_many    :other_party_validation_requests, class_name: "OtherPartyValidationRequest", as: :other_party_requestable, dependent: :destroy

  accepts_nested_attributes_for :certificate_contents, :allow_destroy => false
  attr_accessor :duration
  attr_accessor_with_default :has_csr, false

  #will_paginate
  cattr_reader :per_page
  @@per_page = 10

  #used to temporarily determine lineitem qty
  attr_accessor_with_default :quantity, 1
  preference  :payment_order, :string, :default=>"normal"
  preference  :certificate_chain, :string

  #if the customer has not used this certificate order with a period of time
  #it becomes expired and invalid
  alias_attribute  :expired, :is_expired

  if Proc.new{|co|co.migrated_from_v2?}
    preference  :v2_product_description, :string, :default=>'ssl certificate'
    preference  :v2_line_items, :string
  end

  default_scope joins(:certificate_contents).includes(:certificate_contents).
    order(:created_at.desc).readonly(false)

  scope :search, lambda {|term, options|
    {:conditions => ["ref #{SQL_LIKE} ?", '%'+term+'%']}.merge(options)
  }

  scope :search_with_csr, lambda {|term, options|
    {:conditions => ["csrs.common_name #{SQL_LIKE} ? OR signed_certificates.common_name #{SQL_LIKE} ? OR `certificate_orders`.`ref` #{SQL_LIKE} ?",
      '%'+term+'%', '%'+term+'%', '%'+term+'%'], :joins => {:certificate_contents=>{:csr=>:signed_certificates}}}.
      merge(options)
  }

  scope :unvalidated, where({is_expired: false} & (
    {:certificate_contents=>:workflow_state + ['pending_validation', 'contacts_provided']}))

  scope :incomplete, where({is_expired: false} & (
    {:certificate_contents=>:workflow_state + ['csr_submitted', 'info_provided', 'contacts_provided']}))

  scope :pending, where({:certificate_contents=>:workflow_state + ['pending_validation']})

  scope :has_csr, where({:workflow_state=>'paid'} &
    {:certificate_contents=>{:signing_request.ne=>""}})

  scope :credits, where({:workflow_state=>'paid'} &
    {:certificate_contents=>{workflow_state: "new"}})

  #new certificate orders are the ones still in the shopping cart
  scope :not_new, lambda {|options=nil|
    nn=where(:workflow_state.matches % 'paid')
    nn.includes(options[:include]) if options && options.has_key?(:include)
  }

  scope :unused_credits, where({:workflow_state=>'paid'} &
    {:certificate_contents=>{:workflow_state.eq=>"new"}})

  scope :unused_purchased_credits, where({:workflow_state=>'paid'} & {:amount.gt=> 0} &
    {:certificate_contents=>{:workflow_state.eq=>"new"}})

  scope :unused_free_credits, where({:workflow_state=>'paid'} & {:amount.eq=> 0} &
    {:certificate_contents=>{:workflow_state.eq=>"new"}})

  FULL = 'full'
  EXPRESS = 'express'
  PREPAID_FULL = 'prepaid_full'
  PREPAID_EXPRESS = 'prepaid_express'
  FULL_SIGNUP_PROCESS = {:label=>FULL, :pages=>%w(Submit\ CSR Payment
    Registrant Contacts Provide\ Verification Complete)}
  EXPRESS_SIGNUP_PROCESS = {:label=>EXPRESS,
    :pages=>FULL_SIGNUP_PROCESS[:pages] - %w(Contacts)}
  PREPAID_FULL_SIGNUP_PROCESS = {:label=>PREPAID_FULL,
    :pages=>FULL_SIGNUP_PROCESS[:pages] - %w(Payment)}
  PREPAID_EXPRESS_SIGNUP_PROCESS = {:label=>PREPAID_EXPRESS,
    :pages=>EXPRESS_SIGNUP_PROCESS[:pages] - %w(Payment)}

  CSR_SUBMITTED = :csr_submitted
  INFO_PROVIDED = :info_provided
  REPROCESS_REQUESTED = :reprocess_requested
  CONTACTS_PROVIDED = :contacts_provided

  STATUS = {CSR_SUBMITTED=>'info required',
            INFO_PROVIDED=> 'contacts required',
            REPROCESS_REQUESTED => 'csr required',
            CONTACTS_PROVIDED => 'validation required'}

  RENEWING = 'renewing'
  REPROCESSING = 'reprocessing'
  RECERTS = [RENEWING, REPROCESSING]

  # changed for the migration
  unless MIGRATING_FROM_LEGACY
    validates :certificate, presence: true
  else
    validates :certificate, presence: true, :unless=>Proc.new {|co|
      !co.orders.last.nil? && (co.orders.last.preferred_migrated_from_v2 == true)}
  end

  before_create do |co|
    co.ref='co-'+ActiveSupport::SecureRandom.hex(1)+Time.now.to_i.to_s(32)
    v     =co.create_validation
    co.preferred_certificate_chain = co.certificate.preferred_certificate_chain
    co.certificate.validation_rulings.each do |cvrl|
      vrl = cvrl.clone
      vrl.status = ValidationRuling::WAITING_FOR_DOCS
      vrl.workflow_state = "new"
      v.validation_rulings << vrl
    end
    co.site_seal=SiteSeal.create
  end

  include Workflow
  workflow do
    state :new do
      event :pay, :transitions_to => :paid do |payment|
        halt unless payment
        post_process_csr unless is_prepaid?
      end
    end

    state :paid do
      event :cancel, :transitions_to => :canceled
    end

    state :canceled do
      event :refund, :transitions_to => :refunded do |order_date|
        halt unless has_expired?(order_date)
      end
    end

    state :refunded #only refund a canceled order
  end

  def certificate
    sub_order_items[0].product_variant_item.certificate if sub_order_items[0] &&
        sub_order_items[0].product_variant_item
  end

  def certificate_duration
    if migrated_from_v2? && !preferred_v2_line_items.blank?
      preferred_v2_line_items.split('|').detect{|item|
        item =~/years?/i || item =~/days?/i}.scan(/\d+.+?(?:ear|ay)s?/).last
    else
      sub_order_items.map(&:product_variant_item).detect{|item|
        item.is_duration?}.try(:description)
    end
  end

  def renewal_certificate
    if migrated_from_v2?
      Certificate.map_to_legacy(preferred_v2_product_description, 'renew')
    else
      certificate
    end
  end

  def mapped_certificate
    if migrated_from_v2?
      Certificate.map_to_legacy(preferred_v2_product_description)
    else
      certificate
    end
  end

  def description
    if certificate.is_ucc?
      year = sub_order_items.map(&:product_variant_item).detect(&:is_domain?)
    else
      year = sub_order_items.map(&:product_variant_item).detect(&:is_duration?)
    end
    year.blank? ? "" : (year.value.to_i < 365 ? "#{year.value.to_i} Days" :
        "#{year.value.to_i/365} Year") + " #{certificate.title}"
  end

  def migrated_from_v2?
    order.try(:preferred_migrated_from_v2)
  end

  def signed_certificate
    certificate_content.csr.signed_certificate
  end

  def signup_process(cert=certificate)
    unless is_prepaid?
      if ssl_account && ssl_account.has_role?('reseller')
        unless cert.is_ev?
          EXPRESS_SIGNUP_PROCESS
        else
          FULL_SIGNUP_PROCESS
        end
      else
        FULL_SIGNUP_PROCESS
      end
    else
      prepaid_signup_process(cert)
    end
  end

  def prepaid_signup_process(cert=certificate)
    if ssl_account && ssl_account.has_role?('reseller')
      unless cert.is_ev?
        PREPAID_EXPRESS_SIGNUP_PROCESS
      else
        PREPAID_FULL_SIGNUP_PROCESS
      end
    else
      if cert.is_dv?
        PREPAID_EXPRESS_SIGNUP_PROCESS
      else
        PREPAID_FULL_SIGNUP_PROCESS
      end
    end
  end

  def is_express_signup?
    !signup_process[:label].scan(EXPRESS).blank?
  end

  def is_express_validation?
    validation.validation_rulings.detect(&:new?) &&
      !signup_process[:label].scan(EXPRESS).blank?
  end

  def certificate_content
    certificate_contents.last
  end

  def csr
    certificate_content.csr
  end

  def effective_date
    certificate_content.try("csr").try("signed_certificate").try("effective_date")
  end

  def expiration_date
    certificate_content.csr.signed_certificate.expiration_date
  end

  def subject
    return unless certificate_content.try(:csr)
    csr = certificate_content.csr
    csr.signed_certificate.try(:common_name) || csr.common_name
  end
  alias :common_name :subject

  def order
    orders.last
  end

  def validation_histories
    validation.validation_histories
  rescue
    nil
  end

  def apply_for_certificate
    ComodoApi.apply_for_certificate(self)
  end

  def self.find_not_new(options=nil)
    if options && options.has_key?(:includes)
      includes=method(:includes).call(options[:includes])
    end
    (includes || self).where(:workflow_state.matches % 'paid')
  end

  def to_param
    ref
  end

  def add_renewal(ren)
    unless ren.blank?
      self.renewal_id=CertificateOrder.find_by_ref(ren).id
    end
  end

  def validation_methods
    validation.validation_rules.map(&:applicable_validation_methods).
      flatten.uniq
  end

  def validation_rules_satisfied?
    certificate_content.validated?
  end

  def is_unused_credit?
    certificate_content.try("new?") && workflow_state=='paid'
  end

  def is_prepaid?
    preferred_payment_order=='prepaid'
  end

  def description_with_tier
    return description if certificate.reseller_tier.blank?
    description + " (Tier #{certificate.reseller_tier.label} Reseller)"
  end

  def validation_stage_checkout_in_progress?
    certificate_content.contacts_provided?
  end

  CertificateContent::CONTACT_ROLES.each do |role|
    define_method("#{role}_contact") do
      certificate_content.send("#{role}_contact".intern)
    end
  end

  %W(processed receipt confirmation).each do |et|
    define_method("#{et}_recipients") do
      [].tap do |addys|
        addys << ssl_account.reseller.email if
          ssl_account.is_registered_reseller? &&
          ssl_account.send("preferred_#{et}_include_reseller?")
        et_tmp = (et=="processed" ? "processed_certificate" : et)
        addys << ssl_account.send("preferred_#{et_tmp}_recipients") unless
          ssl_account.send("preferred_#{et_tmp}_recipients")=="0"
        addys << administrative_contact.email if
          administrative_contact &&
            ssl_account.send("preferred_#{et}_include_cert_admin?")
        ct = (et=="processed" ? "tech" : "bill")
        addys << billing_contact.email if
          billing_contact && !et=="processed" &&
          ssl_account.send("preferred_#{et}_include_cert_#{ct}?")
        addys << technical_contact.email if
          technical_contact && et=="processed" &&
          ssl_account.send("preferred_#{et}_include_cert_#{ct}?")
        addys.uniq!
      end
    end
  end

#  def receipt_recipients
#    returning addys = [] do
#      addys << ssl_account.reseller.email if
#        ssl_account.is_registered_reseller? &&
#        ssl_account.preferred_receipt_include_reseller?
#      addys << ssl_account.preferred_receipt_recipients unless
#        ssl_account.preferred_receipt_recipients.empty?
#      addys << administrative_contact.email if
#        ssl_account.preferred_receipt_include_cert_admin?
#      addys << billing_contact.email if
#        ssl_account.preferred_receipt_include_cert_bill?
#      addys.uniq!
#    end
#  end

  def certificate_chain_names
    parse_certificate_chain.transpose[0]
  end

  def certificate_chain_types
    parse_certificate_chain.transpose[1]
  end

  def parse_certificate_chain
    preferred_certificate_chain.split(",").
      map(&:strip).map{|a|a.split(":")}
  end

  def friendly_common_name
    certificate_content.csr.signed_certificate.friendly_common_name
  end

  def request_csr_from

  end

  def v2_line_items
    preferred_v2_line_items.split('|') unless preferred_v2_line_items.blank?
  end

  def v2_line_items=(line_items)
    self.preferred_v2_line_items = line_items.join('|')
  end

  def options_for_ca
    {}.tap do |options|
      certificate_content.csr.tap do |csr|
        options.merge!(
          'test' => Rails.env =~ /production/i ? "N" : 'Y',
          'product' => certificate.comodo_product_id.to_s,
          'serverSoftware' => certificate_content.comodo_server_software_id.to_s,
          'csr' => CGI::escape(csr.body),
          'prioritiseCSRValues' => 'N',
          'isCustomerValidated' => 'Y',
          'responseFormat' => 1,
          'showCertificateID' => 'N',
          'foreignOrderNumber' => ref
        )
        last_sent = csr.domain_control_validations.last_sent
        unless certificate.comodo_product_id==43 #trial cert
          options.merge!('days' => certificate_content.duration.to_s)
        end
        if last_sent.try "is_eligible_to_send?"
          options.merge!('dcvEmailAddress' => last_sent.email_address)
          last_sent.send!
        end
        fill_csr_fields options, certificate_content.registrant
        unless csr.csr_override.blank?
          fill_csr_fields options, csr.csr_override
        end
        if certificate.is_wildcard?
          options.merge!('servers' => server_licenses.to_s || '1')
        end
        if certificate.is_ev?
          certificate_content.tap do |cc|
            options.merge!('joiCountryName'=>(cc.csr.csr_override || cc.registrant).country)
            options.merge!('joiLocalityName'=>(cc.csr.csr_override || cc.registrant).city)
            options.merge!('joiStateOrProvinceName'=>(cc.csr.csr_override || cc.registrant).state)
          end
        end
        if certificate.is_ucc?
          options.merge!(
            'domainNames'=>certificate_content.domains.join(","),
            'primaryDomainName'=>certificate_content.domains.join(",")
          )
        end
      end
    end
  end

  def csr_ca_api_requests
    certificate_contents.map(&:csr).flatten.map(&:ca_certificate_requests)
  end

  private

  def fill_csr_fields(options, obj)
    options.merge!(
      'organizationName' => obj.company_name,
      'organizationalUnitName' => obj.department,
      'postOfficeBox' => obj.po_box,
      'streetAddress1' => obj.address1,
      'streetAddress2' => obj.address2,
      'streetAddress3' => obj.address3,
      'localityName' => obj.city,
      'stateOrProvinceName' => obj.state,
      'postalCode' => obj.postal_code,
      'countryName' => obj.country)
  end

  def post_process_csr
    certificate_content.submit_csr!
    if ssl_account.is_registered_reseller?
      OrderNotifier.deliver_reseller_certificate_order_paid(ssl_account, self)
    else
      receipt_recipients.each do |c|
        OrderNotifier.deliver_certificate_order_paid(c, self)
      end
    end
    site_seal.conditionally_activate!
  end
end
