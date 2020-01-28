# This represents a purchased instance of Product

class ProductOrder < ApplicationRecord
  acts_as_sellable :cents => :amount, :currency => false
  belongs_to  :ssl_account
  belongs_to  :product
  has_many    :users, through: :ssl_account
  has_and_belongs_to_many :parent_product_orders, class_name: 'ProductOrder', association_foreign_key:
      :sub_product_order_id, join_table: 'product_orders_sub_product_orders' # this order belongs to other(s)
  has_and_belongs_to_many :sub_product_orders, class_name: 'ProductOrder', foreign_key:
      :sub_product_order_id, join_table: 'product_orders_sub_product_orders' # this order has other order(s)
  #will_paginate
  cattr_reader :per_page
  @@per_page = 10

  #used to temporarily determine lineitem qty
  attr_accessor :quantity
  preference  :payment_order, :string, :default=>"normal"

  #if the customer has not used this certificate order with a period of time
  #it becomes expired and invalid
  alias_attribute  :expired, :is_expired

  scope :search, lambda {|term, options|
    {:conditions => ["ref #{SQL_LIKE} ?", '%'+term+'%']}.merge(options)
  }

  scope :range, lambda{|start, finish|
    if start.is_a?(String)
      (s= start =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y")
      start = Date.strptime(start, s)
    end
    if finish.is_a?(String)
      (f= finish =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y")
      finish = Date.strptime(finish, f)
    end
    where{created_at >> (start..finish)}
  } do

    def amount
      self.nonfree.sum(:amount)*0.01
    end
  end

  FULL = 'full'
  EXPRESS = 'express'
  PREPAID_FULL = 'prepaid_full'
  PREPAID_EXPRESS = 'prepaid_express'
  VERIFICATION_STEP = 'Perform Validation'
  FULL_SIGNUP_PROCESS = {:label=>FULL, :pages=>%W(Submit\ CSR Payment
    Registrant Contacts #{VERIFICATION_STEP} Complete)}
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

  CA_CERTIFICATES = {SSLcomSHA2: "SSLcomSHA2"}

  STATUS = {CSR_SUBMITTED=>'info required',
            INFO_PROVIDED=> 'contacts required',
            REPROCESS_REQUESTED => 'csr required',
            CONTACTS_PROVIDED => 'validation required'}

  RENEWING = 'renewing'
  REPROCESSING = 'reprocessing'
  RECERTS = [RENEWING, REPROCESSING]
  RENEWAL_DATE_CUTOFF = 45.days.ago
  RENEWAL_DATE_RANGE = 45.days.from_now

  # changed for the migration
  # unless MIGRATING_FROM_LEGACY
  #   validates :certificate, presence: true
  # else
  #   validates :certificate, presence: true, :unless=>Proc.new {|co|
  #     !co.orders.last.nil? && (co.orders.last.preferred_migrated_from_v2 == true)}
  # end

  before_create do |co|
    co.is_expired=false
    co.ref='co-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
  end

  after_initialize do
    if new_record?
      self.quantity ||= 1
    end
  end

  include Workflow
  workflow do
    state :new do
      event :pay, :transitions_to => :paid do |payment|
        halt unless payment
      end
    end

    state :paid do
      event :cancel, :transitions_to => :canceled
      event :refund, :transitions_to => :refunded
      event :charge_back, :transitions_to => :charged_back
      event :start_over, transitions_to: :paid do |complete=false|
        if self.certificate_contents.count >1
          self.certificate_contents.last.delete
        else
          duration = self.certificate_content.duration
          temp_cc=self.certificate_contents.create(duration: duration)
          # Do not delete the last one
          (self.certificate_contents-[temp_cc]).each do |cc|
            cc.delete if ((cc.csr or cc.csr.signed_certificate.blank?) || complete)
          end
        end
      end
    end

    state :canceled do
      event :refund, :transitions_to => :refunded
      event :charge_back, :transitions_to => :charged_back
    end

    state :refunded do #only refund a canceled order
      event :unrefund, :transitions_to => :paid
      event :charge_back, :transitions_to => :charged_back
    end

    state :charged_back
  end

  def duration_remaining(options={duration: :order})
    remaining_days(options)/total_days(options)
  end

  def used_days(options={round: false})
    if signed_certificates && !signed_certificates.empty?
      sum = (Time.now - signed_certificates.sort{|a,b|a.created_at.to_i<=>b.created_at.to_i}.first.effective_date)
      (options[:round] ? sum.round : sum)/1.day
    else
      0
    end
  end

  def remaining_days(options={round: false, duration: :order})
    tot, used = total_days(options), used_days(options)
    if tot && used
      days = total_days(options)-used_days(options)
      (options[:round] ? days.round : days)
    end
  end


  # :actual is based on the duration of the signed cert, :order is the duration based on the certificate order
  def total_days(options={round: false, duration: :order})
    if options[:duration]== :actual
      if signed_certificates && !signed_certificates.empty?
        sum = (signed_certificates.sort{|a,b|a.created_at.to_i<=>b.created_at.to_i}.last.expiration_date -
            signed_certificates.sort{|a,b|a.created_at.to_i<=>b.created_at.to_i}.first.effective_date)
        (options[:round] ? sum.round : sum)/1.day
      else
        0
      end
    else
      certificate_duration(:days)
    end
  end

  # unit can be :days or :years
  def certificate_duration(unit=:as_is)
    years=if migrated_from_v2? && !preferred_v2_line_items.blank?
      preferred_v2_line_items.split('|').detect{|item|
        item =~/years?/i || item =~/days?/i}.scan(/\d+.+?(?:ear|ay)s?/).last
    else
      unless certificate.is_ucc?
        sub_order_items.map(&:product_variant_item).detect{|item|item.is_duration?}.try(:description)
      else
        d=sub_order_items.map(&:product_variant_item).detect{|item|item.is_domain?}.try(:description)
        unless d.blank?
          d=~/(\d years?)/i
          $1
        end
      end
    end
    if unit==:years
      years =~ /\A(\d+)/
      $1
    elsif unit==:days
      case years.gsub(/[^\d]+/,"").to_i
        when 1
          365
        when 2
          730
        when 3
          1095
        when 4
          1461
        when 5
          1826
      end
    elsif unit==:comodo_api
      case years.gsub(/[^\d]+/,"").to_i
        when 1
          365
        when 2
          730
        when 90 #trial
          90
        when 30 #trial
          30
        else #no ssl can go beyond 39 months. 36 months to make adding 1 or 2 years later easier
          1095
      end
    else
      years
    end
  end

  def renewal_certificate
    if migrated_from_v2?
      Certificate.map_to_legacy(preferred_v2_product_description, 'renew')
    elsif certificate.is_free?
      Certificate.for_sale.find_by_product "basicssl"
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
    product.title
  end

  #find the desired Certificate, choose among it’s product_variant_groups, and finally choose among it’s product_variant_items
  #
  #change certificate_order.sub_order_item[0] to the appropriate ProductVariantItem item
  #certificate_content.duration needs to change if not free cert
  #
  #take product_variant_item
  def change_certificate(pvi)
    amount = pvi.amount
    update_attribute :amount, amount #also can update domains, server licenses, etc
    sub_order_items[0].product_variant_item=pvi
    sub_order_items[0].amount=amount
    sub_order_items[0].save
    certificate_content.duration = pvi.duration #for free certs, set to nil

    #change order amount
    line_items[0].update_attribute :cents, amount
    Order.connection.update(
        "UPDATE `orders` SET cents = #{line_items.map(&:cents).sum} WHERE id = #{order.id}") #override readonly

    #Adjust funded account
    ssl_account.funded_account.update_attribute :cents, amount
  end

  def migrated_from_v2?
    order.try(:preferred_migrated_from_v2)
  end

  def signup_process(cert=certificate)
    unless skip_payment?
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

  def self.skip_verification?(certificate)
    certificate.skip_verification?
  end

  def skip_verification?
    self.certificate.skip_verification?
  end

  def order_status
    if is_ev?
      "waiting for documents"
    end
  end

  def prepaid_signup_process(cert=certificate)
    if ssl_account && ssl_account.has_role?('reseller')
      unless cert.is_ev?
        PREPAID_EXPRESS_SIGNUP_PROCESS
      else
        PREPAID_FULL_SIGNUP_PROCESS
      end
    elsif cert.is_browser_generated_capable?
      PREPAID_EXPRESS_SIGNUP_PROCESS
    else
      PREPAID_FULL_SIGNUP_PROCESS
    end
  end

  def express_signup?
    signup_process[:label].scan(EXPRESS).present?
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

  def most_recent_csr
    csrs.compact.last || parent.try(:most_recent_csr)
  end

  def effective_date
    certificate_content.try("csr").try("signed_certificate").try("effective_date")
  end

  def expiration_date
    certificate_content.csr.signed_certificate.expiration_date
  end

  def is_expired_credit?
    is_expired? && certificate_content.new? && created_at < 6.months.ago
  end

  def subject
    return unless certificate_content.try(:csr)
    csr = certificate_content.csr
    csr.signed_certificate.try(:common_name) || csr.common_name
  end
  alias :common_name :subject

  def display_subject
    return unless certificate_content.try(:csr)
    csr = certificate_content.csr
    names=csr.signed_certificate.subject_alternative_names unless csr.signed_certificate.blank?
    names=names.join(", ") unless names.blank?
    names || csr.signed_certificate.try(:common_name) || csr.common_name
  end

  def domains
    if certificate_content.domains.kind_of?(Array)
      certificate_content.domains.flatten
    else
      certificate_content.domains
    end
  end

  def wildcard_domains
    domains.find_all{|d|d=~/\A\*\./} unless domains.blank?
  end

  def nonwildcard_domains
    domains-nonwildcard_domains unless domains.blank?
  end

  # count of domains bought
  # type can be 'wildcard', 'all'
  def purchased_domains(type="nonwildcard")
    soid = sub_order_items.find_all{|item|item.
      product_variant_item.is_domain?}
    case type
      when 'all'
        soid.sum(:quantity)
      when 'wildcard'
        soid.find_all{|item|item.product_variant_item.serial=~ /wcdm/}.sum(&:quantity)
      when 'nonwildcard'
        soid.sum(&:quantity)-soid.find_all{|item|item.product_variant_item.serial=~ /wcdm/}.sum(&:quantity)
    end
  end

  def order(reload=nil)
    orders(reload).last
  end

  def apply_for_certificate(options={})
    ComodoApi.apply_for_certificate(self, options)
  end

  def retrieve_ca_cert(email_customer=false)
    if external_order_number && ca_certificate_requests.first.success?
      retrieve=ComodoApi.collect_ssl(self)
      if retrieve.response_code==2
        csr.signed_certificates.create(body: retrieve.certificate, email_customer: email_customer)
        self.orphaned_certificate_contents remove: true
      end
    end
  end

  def to_param
    ref
  end

  def last_dcv_sent
    return if csr.blank?
    dcvs=csr.domain_control_validations
    (%w(http https).include?(dcvs.last.try(:dcv_method))) ? dcvs.last : dcvs.last_sent
  end


  def self.to_api_string(options={})
    domain = options[:domain_override] || "https://sws-test.sslpki.com"
    options[:action]="create_ssl" if options[:action].blank?
    case options[:action]
      when /create_ssl/
        'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "'+
            {account_key: "#{options[:ssl_account].api_credential.account_key if options[:ssl_account].api_credential}",
             secret_key: "#{options[:ssl_account].api_credential.secret_key if options[:ssl_account].api_credential}",
             product: options[:certificate].api_product_code,
             period: options[:period]}.to_json.gsub("\"","\\\"") +
            "\" #{domain}/certificates"
      when /create_code_signing/
        'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "'+
            {account_key: "#{options[:ssl_account].api_credential.account_key if options[:ssl_account].api_credential}",
             secret_key: "#{options[:ssl_account].api_credential.secret_key if options[:ssl_account].api_credential}",
             product: options[:certificate].api_product_code,
             period: options[:period]}.to_json.gsub("\"","\\\"") +
            "\" #{domain}/certificates"
      when /create_code_signing/
        'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "'+
            {account_key: "#{options[:ssl_account].api_credential.account_key if options[:ssl_account].api_credential}",
             secret_key: "#{options[:ssl_account].api_credential.secret_key if options[:ssl_account].api_credential}",
             product: options[:certificate].api_product_code,
             period: options[:period]}.to_json.gsub("\"","\\\"") +
            "\" #{domain}/certificates"
    end
  end

  def to_api_string(options={action: "update"})
    domain = options[:domain_override] || "https://sws-test.sslpki.com"
    api_contacts, api_domains, cc, registrant_params = base_api_params
    case options[:action]
      when /update_dcv/
        # registrant_params.merge!(api_domains).merge!(api_contacts)
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                    secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}",
                    domains: api_domains}
        options[:caller].blank? ?
          'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X PUT -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /update/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                   secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}",
                   server_software: cc.server_software_id.to_s,
                   domains: api_domains,
                   contacts: api_contacts,
                   csr: certificate_content.csr.body}.merge!(registrant_params)
        # registrant_params.merge!(api_domains).merge!(api_contacts)
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X PUT -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /create_w_csr/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                   secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}",
                   product: certificate.api_product_code,
                   period: certificate_duration(:comodo_api).to_s,
                   server_software: cc.server_software_id.to_s,
                   domains: api_domains,
                   contacts: api_contacts,
                   csr: certificate_content.csr.body}.merge!(registrant_params)
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificates" : api_params
      when /create/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                    secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}",
                    product: certificate.api_product_code,
                    period: certificate_duration(:comodo_api).to_s,
                    domains: api_domains}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificates" : api_params
      when /show/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                   secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}",
                   query_type: ("all_certificates" unless signed_certificate.blank?), show_subscriber_agreement: "Y",
                   response_type: ("individually" unless signed_certificate.blank?)}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /index/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                    secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}"}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificates" : api_params
      when /dcv_emails/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                    secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}"}.
                    merge!(certificate.is_ucc? ? {domains: certificate_content.domains} : {domain: csr.common_name})
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificates/validations/email" : api_params
      when /dcv_methods_wo_csr/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                    secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}"}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificate/#{ref}/validations/methods" : api_params
      when /dcv_methods_w_csr/
        api_params={account_key: "#{ssl_account.api_credential.account_key if ssl_account.api_credential}",
                    secret_key: "#{ssl_account.api_credential.secret_key if ssl_account.api_credential}",
                    csr: certificate_content.csr.body}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "'+
            api_params.to_json.gsub("\"","\\\"") + "\" #{domain}/certificates/validations/csr_hash" : api_params
    end
  end

  def domains_and_common_name
    certificate_content.domains_and_common_name
  end

  def base_api_params
    cc = certificate_content
    r = cc.registrant
    registrant_params = r.blank? ? {} :
        {organization: r.company_name,
         organization_unit: r.department,
         post_office_box: r.po_box,
         street_address_1: r.address1,
         street_address_2: r.address2,
         street_address_3: r.address3,
         locality_name: r.city,
         state_or_province_name: r.state,
         postal_code: r.postal_code,
         country: r.country}
    api_domains = {}
    if !cc.domains.blank?
      (cc.domains.flatten+[common_name]).each { |d|
        cn=cc.certificate_names.find_by_name(d)
        if cn
          api_domains.merge!(d.to_sym => {dcv:
                      cn.domain_control_validations.last_method.try(:method_for_api) ||
                      ApiCertificateCreate_v1_4::DEFAULT_DCV_METHOD })
        end
        }
    elsif cc.csr
      api_domains.merge!(cc.csr.common_name.to_sym => {dcv: "#{last_dcv_sent ? last_dcv_sent.method_for_api : 'http_csr_hash'}"})
    end
    api_contacts = {}
    CertificateContent::CONTACT_ROLES.each do |role|
      contact=cc.certificate_contacts.find do |certificate_contact|
        if certificate_contact.roles.include?(role)
          api_contact={}
          (CertificateContent::RESELLER_FIELDS_TO_COPY+['country']).each do |field|
            api_contact.merge! field.to_sym => "#{certificate_contact.send(field.to_sym)}"
          end
          api_contacts.merge! role.to_sym => api_contact
        end
      end
    end
    return api_contacts, api_domains, cc, registrant_params
  end

  def add_renewal(ren)
    unless ren.blank?
      self.renewal_id=CertificateOrder.find_by_ref(ren).id
    end
  end

  def self.link_renewal(old, new)
    CertificateOrder.find_by_ref(new).update_column :renewal_id, CertificateOrder.find_by_ref(old).id
  end

=begin
  Renews certificate orders and also handles the billing aspects
  Use the order's credit card, then the most recent successfully card card
  Renew for the same number of years as original order
  If order is over a certain amount, notify customer first and let them know they do not need to
  do anything
=end
  # notify can be "none", "success", or "all"
  def do_auto_renew(notify="success")
    #does a credit already exists for this cert order
    if (renewal.blank? || renewal_attempts_old?) && (auto_renew.blank? || auto_renew=="scheduled")
      purchase_renewal(notify)
    end
  end

  def renewal_attempts_old?
    renewal_attempts.blank? ? true : renewal_attempts.last.created_at < RENEWAL_DATE_CUTOFF
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

  def skip_payment?
    !!(is_prepaid? || (certificate_content && certificate_content.preferred_reprocessing?))
  end

  def is_intranet?
    certificate_content.csr.is_intranet? if certificate_content.try(:csr)
  end

  def server_software
    certificate_content.server_software
  end
  alias :software :server_software

  def is_open_ssl?
    [3, 4, 35, 39].include? software.id
  end

  def is_apache?
    [3, 4].include? software.id
  end

  def is_amazon_balancer?
    [39].include? software.id
  end

  def is_iis?
    [18, 19, 20].include? software.id
  end

  def is_nginx?
    [37].include? software.id
  end

  def is_cpanel?
    [35].include? software.id
  end

  def is_red_hat?
    [29].include? software.id
  end

  def is_plesk?
    [25].include? software.id
  end

  def is_heroku?
    [38].include? software.id
  end

  def has_bundle?
    !!(is_red_hat? || is_plesk? || is_heroku? || is_amazon_balancer?)
  end

  def bundle_name
    if has_bundle?
      if is_apache? or is_amazon_balancer?
        'Apache bundle (SSLCACertificateFile)'
      elsif is_red_hat? || is_plesk?
        'ca bundle (Apache SSLCACertificateFile)'
      elsif is_heroku?
        'ca bundle for Heroku'
      end
    else
      ""
    end
  end

  def status
    if certificate_content.new?
      "unused. waiting on certificate signing request (csr) from customer"
    elsif certificate_content.expired?
      'n/a'
    else
      case certificate_content.workflow_state
        when "csr_submitted"
          "waiting on registrant information from customer"
        when "info_provided"
          "waiting on contacts information from customer"
        when "reprocess_requested"
          "reissue requested. waiting on certificate signing request (csr)from customer"
        when "contacts_provided"
          "waiting on validation from customer"
        when "pending_validation", "validated"
          last_sent=csr.last_dcv
          if last_sent.blank?
            'validating, please wait' #assume intranet
          elsif %w(http https cname http_csr_hash https_csr_hash cname_csr_hash).include?(last_sent.try(:dcv_method))
            'validating, please wait'
          else
            "waiting validation email response from customer"
          end
        when "issued"
          if certificate_content.expiring?
            if renewal && renewal.paid?
              "renewed. see #{renewal.ref} for renewal"
            else
              "expiring. renew soon"
            end
          else
            "issued"
          end
        when "canceled"
      end
    end
  end

  # depending on the server software type we will bundle different root and intermediate certs
  # override is a target server software other than the default one for this order
  def bundled_cert_names(override={})
    if self.ca == CA_CERTIFICATES[:SSLcomSHA2]
      if (is_open_ssl? && override[:components].blank?) || override[:is_open_ssl]
        #attach bundle
        Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:labels].select do |k,v|
          if signed_certificate.try("is_ev?".to_sym)
            k=="sslcom_ev_ca_bundle#{'_amazon' if is_amazon_balancer? || override[:server]=="amazon"}.txt"
          elsif signed_certificate.try("is_dv?".to_sym)
            k=="sslcom_addtrust_ca_bundle#{'_amazon' if is_amazon_balancer? || override[:server]=="amazon"}.txt"
          elsif signed_certificate.try("is_ov?".to_sym)
            k=="sslcom_high_assurance_ca_bundle#{'_amazon' if is_amazon_balancer? || override[:server]=="amazon"}.txt"
          elsif certificate.is_ev?
            k=="sslcom_ev_ca_bundle#{'_amazon' if is_amazon_balancer? || override[:server]=="amazon"}.txt"
          elsif certificate.is_essential_ssl?
            k=="sslcom_addtrust_ca_bundle#{'_amazon' if is_amazon_balancer? || override[:server]=="amazon"}.txt"
          else
            k=="sslcom_high_assurance_ca_bundle#{'_amazon' if is_amazon_balancer? || override[:server]=="amazon"}.txt"
          end
        end.map{|k,v|k}
      else
        if signed_certificate.try("is_ev?".to_sym)
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_ev#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        elsif signed_certificate.try("is_dv?".to_sym)
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_dv#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        elsif signed_certificate.try("is_ov?".to_sym)
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_ov#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        elsif certificate.is_ev?
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_ev#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        elsif certificate.is_essential_ssl?
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_dv#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        else
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_ov#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        end
      end
    else
      if is_open_ssl? && override[:components].blank?
        #attach bundle
        Certificate::COMODO_BUNDLES.select do |k,v|
          if certificate.serial=~/256sslcom/
            if signed_certificate.try("is_ev?".to_sym)
              k=="sslcom_ev_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
              #elsif certificate.is_free?
              #  k=="sslcom_free_ca_bundle.txt"
            elsif signed_certificate.try("is_dv?".to_sym)
              k=="sslcom_addtrust_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
            elsif signed_certificate.try("is_ov?".to_sym)
              k=="sslcom_high_assurance_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
            elsif certificate.is_ev?
              k=="sslcom_ev_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
              #elsif certificate.is_free?
              #  k=="sslcom_free_ca_bundle.txt"
            elsif certificate.is_essential_ssl?
              k=="sslcom_addtrust_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
            else
              k=="sslcom_high_assurance_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
            end
          elsif certificate.comodo_product_id==342
            k=="free_ssl_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
          elsif certificate.comodo_product_id==43
            k=="trial_ssl_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
          else
            k=="ssl_ca_bundle#{'_amazon' if is_amazon_balancer?}.txt"
          end
        end.map{|k,v|k}
      else
        Certificate::COMODO_BUNDLES.select do |k,v|
          if certificate.serial=~/256sslcom/
            if signed_certificate.try("is_ev?".to_sym)
              %w(SSLcomPremiumEVCA.crt COMODOAddTrustServerCA.crt AddTrustExternalCARoot.crt).include? k
            elsif signed_certificate.try("is_dv?".to_sym)
              %w(SSLcomAddTrustSSLCA.crt AddTrustExternalCARoot.crt).include? k
            elsif signed_certificate.try("is_ov?".to_sym)
              %w(SSLcomHighAssuranceCA.crt AddTrustExternalCARoot.crt).include? k
            elsif certificate.is_ev?
              %w(SSLcomPremiumEVCA.crt COMODOAddTrustServerCA.crt AddTrustExternalCARoot.crt).include? k
            elsif certificate.is_essential_ssl?
              %w(SSLcomAddTrustSSLCA.crt AddTrustExternalCARoot.crt).include? k
            else
              %w(SSLcomHighAssuranceCA.crt AddTrustExternalCARoot.crt).include? k
            end
          elsif [342, 343].include? certificate.comodo_product_id
            %w(UTNAddTrustSGCCA.crt EssentialSSLCA_2.crt ComodoUTNSGCCA.crt AddTrustExternalCARoot.crt).include? k
          elsif certificate.comodo_product_id==337 #also maybe 410 (evucc) we'll get there when we place that order
            %w(COMODOExtendedValidationSecureServerCA.crt COMODOAddTrustServerCA.crt AddTrustExternalCARoot.crt).include? k
          elsif certificate.comodo_product_id==361
            %w(EntrustSecureServerCA.crt USERTrustLegacySecureServerCA.crt).include? k
          else
            %w(SSLcomHighAssuranceCA.crt AddTrustExternalCARoot.crt).include? k
          end
        end.map{|k,v|k}
      end
    end
  end

  def bundled_cert_dir
    if self.ca == CA_CERTIFICATES[:SSLcomSHA2]
      Settings.intermediate_certs_path+Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:dir]+"/"
    else
      Settings.intermediate_certs_path
    end
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
      end.uniq
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
    certificate_content.csr.signed_certificate.nonidn_friendly_common_name
  end

  def request_csr_from

  end

  def v2_line_items
    preferred_v2_line_items.split('|') unless preferred_v2_line_items.blank?
  end

  def v2_line_items=(line_items)
    self.preferred_v2_line_items = line_items.join('|')
  end

  def options_for_ca(options={})
    {}.tap do |params|
      cc=(options[:certificate_content] || certificate_content)
      cc.csr.tap do |csr|
        update_attribute(:ca, CA_CERTIFICATES[:SSLcomSHA2]) if self.ca.blank?
        if options[:new].blank? && (csr.sent_success || external_order_number)
          #assume reprocess, will need to look at ucc more carefully
          params.merge!(
            'orderNumber' => external_order_number,
            'csr' => csr.to_api,
            'prioritiseCSRValues' => 'N',
            'isCustomerValidated' => 'N',
            'responseFormat' => 1,
            'showCertificateID' => 'N',
            'foreignOrderNumber' => ref,
            'countryName'=>csr.country
          )
          set_comodo_subca(params,options)
          last_sent = csr.domain_control_validations.last_method
          build_comodo_dcv(last_sent, params, options)
        else
          params.merge!(
            'test' => (is_test || !(Rails.env =~ /production/i)) ? "Y" : "N",
            'product' => options[:product] || mapped_certificate.comodo_product_id.to_s,
            'serverSoftware' => cc.comodo_server_software_id.to_s,
            'csr' => csr.to_api,
            'prioritiseCSRValues' => 'N',
            'isCustomerValidated' => 'N',
            'responseFormat' => 1,
            'showCertificateID' => 'N',
            'foreignOrderNumber' => ref
          )
          last_sent = csr.last_dcv
          #43 is the old comodo 30 day trial
          #look at certificate_duration for more guidance, i don't think the following is ucc safe
          days = certificate_duration(:comodo_api)
          # temporary for a certain customer wanting to move over a number of domains to ssl.com
          if [Certificate::COMODO_PRODUCT_MAPPINGS["free"], 43].include?(
              mapped_certificate.comodo_product_id) #trial cert does not specify duration
            params.merge!('days' => (days).to_s)
          else
            params.merge!('days' => (days+csr.days_left).to_s)
          end
          #ssl.com Sub CA certs
          set_comodo_subca(params,options)
          build_comodo_dcv(last_sent, params, options)
          fill_csr_fields(params, cc.registrant)
          unless csr.csr_override.blank?
            fill_csr_fields params, csr.csr_override
          end
          if false #TODO make country override option
            override_params(params) #essentialssl
          end
          if certificate.is_wildcard?
            params.merge!('servers' => server_licenses.to_s || '1')
          end
        end
        if certificate.is_ev?
          params.merge!('joiCountryName'=>(cc.csr.csr_override || cc.registrant).country)
          params.merge!('joiLocalityName'=>(cc.csr.csr_override || cc.registrant).city)
          params.merge!('joiStateOrProvinceName'=>(cc.csr.csr_override || cc.registrant).state)
        end
        if certificate.is_ucc?
          params.merge!(
            'primaryDomainName'=>csr.common_name.downcase,
            'maxSubjectCNs'=>1
          )
          params.merge!('days' => '1095') if params['days'].to_i > 1095 #Comodo doesn't support more than 3 years
        end
      end
    end
  end

  def override_params(options)
    options["countryName"]="US"
    options["prioritiseCSRValues"]="N"
    # options["product"]=301 #essentialssl
    # options.merge!('caCertificateID' => 401) #essentialssl
  end

  def build_comodo_dcv(last_sent, params, options={})
    if certificate.is_ucc?
      dcv_methods_for_comodo=[]
      new_domains, csr = (options[:certificate_content] ?
          [options[:certificate_content].domains, options[:certificate_content].csr] : [self.domains, self.csr])
      domains_for_comodo = (new_domains.blank? ? [csr.common_name] : ([csr.common_name]+new_domains)).flatten.uniq
      domains_for_comodo.each do |d|
        if certificate_content.certificate_names.find_by_name(d)
          last = certificate_content.certificate_names.find_by_name(d).last_dcv_for_comodo
          dcv_methods_for_comodo << (last.blank? ? ApiCertificateCreate_v1_4::DEFAULT_DCV_METHOD_COMODO : last)
        end
      end
      params.merge!('domainNames' => domains_for_comodo.join(","))
      params.merge!('dcvEmailAddresses' => dcv_methods_for_comodo.join(",")) if (dcv_methods_for_comodo && dcv_methods_for_comodo.count==domains_for_comodo.count)
    else
      if last_sent.blank? || last_sent.dcv_method=="http"
        params.merge!('dcvMethod' => "HTTP_CSR_HASH")
      elsif last_sent.dcv_method=="https"
        params.merge!('dcvMethod' => "HTTPS_CSR_HASH")
      elsif last_sent.try("is_eligible_to_send?")
        params.merge!('dcvEmailAddress' => last_sent.email_address)
        last_sent.send_dcv! unless last_sent.sent_dcv?
      end
    end
  end

  # Creates a new external ca order history by deleting the old external order id and requests thus allowing us
  # to start a new history with comodo for an existing ssl.com cert order
  # useful in the event Comodo take forever to make changes to an existing order (and sometimes cannot) so we
  # just create a new one and have the old one refunded
  def reset_ext_ca_order
    csrs.compact.map(&:sent_success).flatten.compact.uniq.each{|a|a.delete}
    cc=certificate_content
    cc.preferred_reprocessing = false
    cc.save validation: false
  end

  def change_ext_ca_order(new_number)
    ss=csrs.compact.map(&:sent_success).flatten.compact.last
    ss.update_column :response, ss.response.gsub(external_order_number, new_number.to_s)
    update_column :external_order_number, new_number
  end

  # Resets this order as if it never processed
  #   <tt>complete</tt> - removes the certificate_content (and it's csr and other properties)
  #   <tt>ext_ca_orders</tt> - removes the external calls history to comodo for this order
  def reset(complete=false,ext_ca_orders=false)
    self.reset_ext_ca_order if ext_ca_orders
    self.certificate_content.csr.delete unless certificate_content.csr.blank?

    self.start_over!(complete) unless ['canceled', 'revoked'].
        include?(self.certificate_content.workflow_state)
  end

  # Removes any certificate_contents that were not processed, except the last one
  def orphaned_certificate_contents(options={})
    cc_count = self.certificate_contents.count
    return nil if cc_count <= 1
    ccs = []
    certificate_contents.each_with_index do |cc, i|
      next if i == cc_count-1 # ignore the most recent certificate_content
      if (cc.csr.blank? || cc.csr.signed_certificate.blank?)
        if options[:remove]
          cc.destroy
        else
          ccs << cc
        end
      end
    end
    ccs unless options[:remove]
  end

  def self.remove_all_orphaned
    self.find_each{|co|co.orphaned_certificate_contents remove: true}
  end

  # Removes the last certificate_content in the event it was a mistake
  def remove_last_certificate_content
    self.certificate_content.destroy if self.certificate_contents.count > 1
  end

  def external_order_number_meta(options={})
    if notes =~ /(DV|EV|OV)\#\d+/
      if options[:external_order_number] && notes =~ /(DV|EV|OV)\##{options[:external_order_number]}/
        return $1
      elsif options[:validation_type] && notes =~ /#{options[:validation_type]}\#(\d+)/
        return $1
      else
        return external_order_number_meta(external_order_number: external_order_number)
      end
    end
  end

  def sent_success_count
    sent_success_map = csrs.map(&:sent_success)
    sent_success_map.flatten.compact.uniq.count if
        csrs && !sent_success_map.blank?
  end

  # Get the most recent certificate_id (useful for UCC replacements)
  def external_certificate_id
    all_csrs = certificate_contents.map(&:csr)
    sent_success_map = all_csrs.map(&:sent_success)
    sent_success_map.flatten.compact.uniq.first.certificate_id if
        all_csrs && !sent_success_map.blank? &&
        sent_success_map.flatten.compact.uniq.first
    #all_csrs.sent_success.order_number if all_csrs && all_csrs.sent_success
  end

  def transfer_certificate_content(certificate_content)
    self.site_seal.conditionally_activate! unless self.site_seal.conditionally_activated?
    cc = self.certificate_content
    if certificate_content.preferred_reprocessing?
      self.certificate_contents << certificate_content
      certificate_content.create_registrant(cc.registrant.attributes.except(*CertificateOrder::ID_AND_TIMESTAMP)).save
      cc.certificate_contacts.each do |contact|
        certificate_content.certificate_contacts << CertificateContact.new(contact.attributes.
            except(*CertificateOrder::ID_AND_TIMESTAMP))
      end
      cc = self.certificate_content
    else
      cc.signing_request = certificate_content.signing_request
      cc.server_software = certificate_content.server_software
    end
    if cc.new?
      cc.submit_csr!
    elsif cc.validated? || cc.pending_validation?
      cc.pend_validation! if cc.validated?
    end
    cc
  end

  def all_domains
    certificate_content.all_domains
  end

  private

  def fill_csr_fields(options, obj)
    f= {'organizationName' => obj.company_name,
          'organizationalUnitName' => obj.department,
          'postOfficeBox' => obj.po_box,
          'streetAddress1' => obj.address1,
          'streetAddress2' => obj.address2,
          'streetAddress3' => obj.address3,
          'localityName' => obj.city,
          'stateOrProvinceName' => obj.state,
          'postalCode' => obj.postal_code,
          'countryName' => obj.country}
    options.merge!(f.each{|k,v|f[k]=CGI.escape(v) unless v.blank?})
  end

  def post_process_csr
    certificate_content.submit_csr!
    if ssl_account.is_registered_reseller?
      OrderNotifier.reseller_certificate_order_paid(ssl_account, self).deliver
    else
      receipt_recipients.each do |c|
        OrderNotifier.certificate_order_paid(c, self).deliver
      end
    end
    site_seal.conditionally_activate!
  end

  # will cycle through billing profile to purchase certificate order
  # use the billing profile associated with this order
  # otherwise, find most recent successfully purchased order and use it's billing profile,
  # cannot rely on order transactions, since the data was not migrated

  # notify can be "none", "success", or "all"
  def purchase_renewal(notify)
    bp=order.billing_profile
    response=[bp, (ssl_account.cached_orders.map(&:billing_profile)-[bp]).shift].compact.each do |bp|
      p "purchase using billing_profile_id==#{bp.id}"
      options={profile: bp, cvv: false}
      new_cert = self.dup
      new_cert.certificate_contents.build
      new_cert.duration=1 #only renew 1 year at a time
      co = Order.setup_certificate_order(certificate: renewal_certificate, certificate_order: new_cert)
      co.parent = self
      reorder=ssl_account.purchase co
      reorder.cents = co.attributes_before_type_cast["amount"].to_f
      gateway_response=reorder.rebill(options)
      RenewalAttempt.create(
          certificate_order_id: self.id, order_transaction_id: gateway_response.id)
      if gateway_response.success?
        #self.quantity=1
        #clone_for_renew([self], reorder)
        #reorder.line_items.last.sellable.update_attribute :renewal_id, self.id
        co.save
        reorder.save
        if notify=="success"
          begin
            logger.info "Sending notification to #{receipt_recipients.join(",")}"
            body = OrderNotifier.certificate_order_paid(receipt_recipients, co, true)
            body.deliver unless body.to.empty?
            RenewalNotification.create(certificate_order_id:
                co.id, subject: body.subject,
                body: body, recipients: receipt_recipients)
          rescue Exception=>e
            logger.error e.backtrace.inspect
            raise e
          end
        end
        return gateway_response
      else
        co.destroy
      end
      gateway_response
    end.last
  end

  #def purchase_using(profile)
  #  credit_card = ActiveMerchant::Billing::CreditCard.new({
  #    :first_name => profile.first_name,
  #    :last_name  => profile.last_name,
  #    :number     => profile.card_number,
  #    :month      => profile.expiration_month,
  #    :year       => profile.expiration_year
  #  })
  #  credit_card.type = 'bogus' if defined?(::GATEWAY_TEST_CODE)
  #end

  def clone_for_renew(certificate_orders, order)
    certificate_orders.each do |cert|
      cert.quantity.times do |i|
        #could use cert.dup after >=3.1, but we are currently on 3.0.10 so we'll do this manually
        new_cert = cert.dup
        cert.sub_order_items.each {|soi|
          new_cert.sub_order_items << soi.dup
        }
        if cert.migrated_from_v2?
          pvg = new_cert.sub_order_items[0].
              product_variant_item.product_variant_group
          pvg.variantable=cert.renewal_certificate
          pvg.save
        end
        new_cert.line_item_qty = cert.quantity if(i==cert.quantity-1)
        new_cert.preferred_payment_order = 'prepaid'
        new_cert.save
        cc = CertificateContent.new
        cc.certificate_order=new_cert
        cc.save
        order.line_items.build :sellable=>new_cert
      end
    end
  end

  # used for determining which Sub Ca certs to use
  def set_comodo_subca(params, options={})
    cci=Settings.ca_certificate_id_dv
    if options[:ca_certificate_id]
      cci = options[:ca_certificate_id]
    elsif [CA_CERTIFICATES[:SSLcomSHA2]].include? self.ca
      cci = if Settings.send_dv_first and external_order_number.blank?
              Settings.ca_certificate_id_dv #first time needs to be DV
            elsif external_order_number_meta=="EV"
              Settings.ca_certificate_id_ev
            elsif external_order_number_meta=="OV"
              Settings.ca_certificate_id_ov
            elsif external_order_number_meta=="DV"
              Settings.ca_certificate_id_dv
            elsif certificate.is_ev?
              Settings.ca_certificate_id_ev
            elsif certificate.is_ov?
              Settings.ca_certificate_id_ov
            else
              Settings.ca_certificate_id_dv
            end
    elsif certificate.serial=~/256sslcom/
      cci = if certificate.is_ev?
                    "403"
                  elsif certificate.is_essential_ssl?
                    "401"
                  else
                    "402"
                  end
    end
    params.merge!('caCertificateID' => cci.to_s)
  end


  def self.trial_conversions(start=30.days.ago, finish=Date.today)
    free, nonfree, result, stats, count = {}, {}, {}, [], 0
    CertificateOrder.range(start, finish).not_test.free.map{|co|free.merge!(co.id.to_s => co.all_domains) unless co.all_domains.blank?}
    CertificateOrder.range(start, finish).not_test.nonfree.map{|co|nonfree.merge!(co.id.to_s => co.all_domains) unless co.all_domains.blank?}
    nonfree.each do |nk,nv|
      free.each do |fk,fv|
        if !(nv & fv).empty?
          count+=1
          co_fk = CertificateOrder.find(fk)
          co_nk = CertificateOrder.find(nk)
          result.merge!([co_fk.ref, 0.01*co_fk.amount, co_fk.created_at.strftime("%b %d, %Y")]=>
                            [co_nk.ref, 0.01*co_nk.amount, co_nk.created_at.strftime("%b %d, %Y")])
          stats<<[co_fk.ref, 0.01*co_fk.amount, co_fk.created_at.strftime("%b %d, %Y"),
              co_nk.ref, 0.01*co_nk.amount, co_nk.created_at.strftime("%b %d, %Y")].join("/")
          free.delete fk
          break
        end
      end
    end
    File.open("/tmp/trial_conversions.txt", "w") { |file| file.write stats.join("\n") }
    [count,result]
  end

end
