class CertificateOrder < ActiveRecord::Base
  include V2MigrationProgressAddon
  #using_access_control
  acts_as_sellable :cents => :amount, :currency => false
  belongs_to  :ssl_account
  belongs_to  :validation
  belongs_to  :site_seal
  belongs_to  :parent, class_name: 'CertificateOrder', :foreign_key=>:renewal_id
  has_one     :renewal, class_name: 'CertificateOrder', :foreign_key=>:renewal_id,
    :dependent=>:destroy #represents a child renewal
  has_many    :renewal_attempts
  has_many    :renewal_notifications
  has_many    :certificate_contents, :dependent => :destroy
  has_many    :csrs, :through=>:certificate_contents, :dependent => :destroy
  has_many    :sub_order_items, :as => :sub_itemable, :dependent => :destroy
  has_many    :orders, :through => :line_items, :include => :stored_preferences
  has_many    :other_party_validation_requests, class_name: "OtherPartyValidationRequest",
              as: :other_party_requestable, dependent: :destroy
  has_many    :ca_retrieve_certificates, as: :api_requestable, dependent: :destroy
  #has_many    :client_order_certificate_requests, class_name: "ClientOrderCertificateRequest",
  #            as: :api_requestable, dependent: :destroy

  accepts_nested_attributes_for :certificate_contents, :allow_destroy => false
  attr_accessor :duration, :has_csr

  # the following only apply to api calls
  attr_accessor :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :dcv_method,
      :dcv_email_address, :dcv_email_addresses, :is_api_call

  #will_paginate
  cattr_reader :per_page
  @@per_page = 10

  #used to temporarily determine lineitem qty
  attr_accessor :quantity
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

  scope :not_test, where{(is_test == nil) | (is_test==false)}

  scope :search, lambda {|term, options|
    {:conditions => ["ref #{SQL_LIKE} ?", '%'+term+'%']}.merge(options)
  }

  scope :search_signed_certificates, lambda {|term|
    joins{certificate_contents.csr.signed_certificates}.
      where{certificate_contents.csr.signed_certificates.common_name =~ "%#{term}%"}
  }

  scope :search_csr, lambda {|term|
    joins{certificate_contents.csr}.where{certificate_contents.csr.common_name =~ "%#{term}%"}
  }

  scope :search_with_csr, lambda {|term, options|
    cids=SignedCertificate.select{csr_id}.where{common_name=~"%#{term}%"}.map(&:csr_id)
    {:conditions => ["csrs.common_name #{SQL_LIKE} ? #{"OR csrs.id IN (#{cids.join(",")})" unless cids.empty?} OR `certificate_orders`.`ref` #{SQL_LIKE} ?",
      '%'+term+'%', '%'+term+'%'], :joins => {:certificate_contents=>:csr}, select: "distinct certificate_orders.*"}.
      merge(options)
  }

  scope :reprocessing, lambda {
    cids=Preference.select("owner_id").joins{owner(CertificateContent)}.
        where{(name=="reprocessing") & (value==1)}.map(&:owner_id)
    joins{certificate_contents.csr}.where{certificate_contents.id >> cids}.
        order(:certificate_contents=>{:csr=>:updated_at.desc})
  }

  scope :order_by_csr, lambda {
    joins{certificate_contents.csr}.order({:certificate_contents=>{:csr=>:updated_at.desc}})
  }

  scope :unvalidated, where{(is_expired==false) &
    (certificate_contents.workflow_state >> ['pending_validation', 'contacts_provided'])}.
      order(:certificate_contents=>:updated_at)

  scope :incomplete, where{(is_expired==false) &
    (certificate_contents.workflow_state >> ['csr_submitted', 'info_provided', 'contacts_provided'])}.
      order(:certificate_contents=>:updated_at)

  scope :pending, where{certificate_contents.workflow_state >> ['pending_validation', 'validated']}.
      order(:certificate_contents=>:updated_at)

  scope :has_csr, where{(workflow_state=='paid') &
    (certificate_contents.signing_request != "")}.order(:certificate_contents=>:updated_at)

  scope :credits, where({:workflow_state=>'paid'} & {is_expired: false} &
    {:certificate_contents=>{workflow_state: "new"}})

  #new certificate orders are the ones still in the shopping cart
  scope :not_new, lambda {|options=nil|
    if options && options.has_key?(:includes)
      includes=method(:includes).call(options[:includes])
    end
    (includes || self).where(:workflow_state.matches % 'paid').select("distinct certificate_orders.*")
  }

  scope :unrenewed, not_new.where(:renewal_id=>nil)

  scope :renewed, not_new.where{:renewal_id != nil}

  scope :nonfree, not_new.where(:amount.gt => 0)

  scope :free, not_new.where(:amount => 0)

  scope :unused_credits, where({:workflow_state=>'paid'} & {is_expired: false} &
    {:certificate_contents=>{:workflow_state.eq=>"new"}})

  scope :unused_purchased_credits, where({:workflow_state=>'paid'} & {:amount.gt=> 0} & {is_expired: false} &
    {:certificate_contents=>{:workflow_state.eq=>"new"}})

  scope :unused_free_credits, where({:workflow_state=>'paid'} & {:amount.eq=> 0} & {is_expired: false} &
    {:certificate_contents=>{:workflow_state.eq=>"new"}})

  scope :range, lambda{|start, finish|
    if start.is_a? String
      s= start =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
      f= finish =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
      start = Date.strptime start, s
      finish = Date.strptime finish, f
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
  VERIFICATION_STEP = 'Provide Verification'
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
  unless MIGRATING_FROM_LEGACY
    validates :certificate, presence: true
  else
    validates :certificate, presence: true, :unless=>Proc.new {|co|
      !co.orders.last.nil? && (co.orders.last.preferred_migrated_from_v2 == true)}
  end

  before_create do |co|
    co.is_expired=false
    co.ref='co-'+SecureRandom.hex(1)+Time.now.to_i.to_s(32)
    v     =co.create_validation
    co.preferred_certificate_chain = co.certificate.preferred_certificate_chain
    co.certificate.validation_rulings.each do |cvrl|
      vrl = cvrl.dup
      vrl.status = ValidationRuling::WAITING_FOR_DOCS
      vrl.workflow_state = "new"
      v.validation_rulings << vrl
    end
    co.site_seal=SiteSeal.create
  end

  after_initialize do
    if new_record?
      self.quantity ||= 1
      self.has_csr ||= false
    end
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
      event :start_over, transitions_to: :paid do
        certificate_contents.create(duration: self.certificate_content.duration)
      end
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
  end


  def certificate_duration_in_days
    case certificate_duration.gsub(/[^\d]+/,"").to_i
      when 1
        365
      when 2
        720
      when 3
        1095
      when 4
        1460
      when 5
        1825
    end
  end

  def renewal_certificate
    if migrated_from_v2?
      Certificate.map_to_legacy(preferred_v2_product_description, 'renew')
    elsif certificate.is_free?
      Certificate.for_sale.find_by_product "high_assurance"
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

  def signed_certificate
    certificate_content.csr.signed_certificate
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
    certificate.is_ucc? #certificate.skip_verification?
  end

  def skip_verification?
    (certificate.is_ucc? && !certificate.is_ev?) || ((csr.is_intranet? || csr.is_ip_address?) if csr)
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
    else
      PREPAID_FULL_SIGNUP_PROCESS
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

  def retrieve_ca_cert(email_customer=false)
    return nil unless external_order_number
    retrieve=ComodoApi.collect_ssl(self)
    csr.signed_certificates.create(body: retrieve.certificate,
                                   email_customer: email_customer) if retrieve.response_code==2
  end

  def self.retrieve_ca_certs(start, finish)
    #cos=range(start, finish).pending
    cos=Csr.range(start, finish).pending.map(&:certificate_orders).flatten.uniq
    cos.each{|co|co.retrieve_ca_cert(true)}
  end

  def self.find_not_new(options=nil)
    if options && options.has_key?(:includes)
      includes=method(:includes).call(options[:includes])
    end
    (includes || self).select("distinct certificate_orders.*").where(:workflow_state.matches % 'paid')
  end

  def to_param
    ref
  end

  def add_renewal(ren)
    unless ren.blank?
      self.renewal_id=CertificateOrder.find_by_ref(ren).id
    end
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

  def setup_certificate_order(certificate, certificate_order)
    duration = certificate.duration_in_days(certificate_order.duration)
    certificate_order.certificate_content.duration = duration
    if certificate.is_ucc? || certificate.is_wildcard?
      psl = certificate.items_by_server_licenses.find { |item|
        item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>psl,
       :quantity            =>certificate_order.server_licenses.to_i,
       :amount              =>psl.amount*certificate_order.server_licenses.to_i)
      certificate_order.sub_order_items << so
      if certificate.is_ucc?
        pd                 = certificate.items_by_domains.find_all { |item|
          item.value==duration.to_s }
        additional_domains = (certificate_order.certificate_contents[0].
            domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so                 = SubOrderItem.new(:product_variant_item=>pd[0],
                                              :quantity            =>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
                                              :amount              =>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        certificate_order.sub_order_items << so
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
                                :quantity            =>additional_domains,
                                :amount              =>pd[1].amount*additional_domains)
          certificate_order.sub_order_items << so
        end
      end
    end
    unless certificate.is_ucc?
      pvi = certificate.items_by_duration.find { |item| item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
                             :amount              =>pvi.amount)
      certificate_order.sub_order_items << so
    end
    certificate_order.amount = certificate_order.
        sub_order_items.map(&:amount).sum
    certificate_order.certificate_contents[0].
        certificate_order    = certificate_order
    certificate_order
  end

  def refund

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
    !!(is_apache? || is_nginx? || is_cpanel? || is_red_hat? || is_plesk? || is_heroku? || is_amazon_balancer?)
  end

  def bundle_name
    if has_bundle?
      if is_apache?
        'Apache bundle (SSLCACertificateFile)'
      elsif is_amazon_balancer?
        'Amazon bundle (SSLCACertificateFile)'
      elsif is_nginx?
        'Nginx bundle'
      elsif is_cpanel? || is_red_hat? || is_plesk?
        'ca bundle (Apache SSLCACertificateFile)'
      elsif is_heroku?
        'ca bundle for Heroku'
      end
    else
      ""
    end
  end

  def file_extension
    is_iis? ? '.cer' : '.crt'
  end

  def file_type
    is_iis? ? 'PKCS#7' : 'X.509'
  end

  # depending on the server software type we will bundle different root and intermediate certs
  # override is a target server software other than the default one for this order
  def bundled_cert_names(override=nil)
    if is_open_ssl?
      #attach bundle
      Certificate::COMODO_BUNDLES.select do |k,v|
        if certificate.serial=~/256sslcom/
          if certificate.is_ev?
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
          if certificate.is_ev?
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
        if csr.certificate_content.preferred_reprocessing? || csr.sent_success
          #assume reprocess, will need to look at ucc more carefully
          options.merge!(
            'orderNumber' => external_order_number,
            'csr' => CGI::escape(csr.body),
            'prioritiseCSRValues' => 'N',
            'isCustomerValidated' => 'Y',
            'responseFormat' => 1,
            'showCertificateID' => 'N',
            'foreignOrderNumber' => ref,
            'countryName'=>csr.country
          )
          ssl_com_order(options)
          last_sent = csr.domain_control_validations.last_sent
          if !skip_verification? && !last_sent.blank?
            if last_sent.dcv_method=="http"
              options.merge!('dcvMethod' => "HTTP_CSR_HASH")
            elsif last_sent.try("is_eligible_to_send?")
              options.merge!('dcvEmailAddress' => last_sent.email_address)
              last_sent.send_dcv! unless last_sent.sent_dcv?
            end
          end
        else
          options.merge!(
            'test' => Rails.env =~ /production/i ? (is_test ? "Y" : "N") : 'Y',
            'product' => mapped_certificate.comodo_product_id.to_s,
            'serverSoftware' => certificate_content.comodo_server_software_id.to_s,
            'csr' => CGI::escape(csr.body),
            'prioritiseCSRValues' => 'Y',
            'isCustomerValidated' => 'Y',
            'responseFormat' => 1,
            'showCertificateID' => 'N',
            'foreignOrderNumber' => ref
          )
          last_sent = csr.last_dcv
          #43 is the old comodo 30 day trial
          unless [Certificate::COMODO_PRODUCT_MAPPINGS["free"], 43].include?(
              mapped_certificate.comodo_product_id) #trial cert does not specify duration
            #look at certificate_duration for more guidance, i don't think the following is ucc safe
            days = (migrated_from_v2? && !preferred_v2_line_items.blank?) ? certificate_duration_in_days :
                certificate_content.duration
            # temporary for a certain customer wanting to move over a number of domains to ssl.com
            days += 60 if
                %w(myevaluations.com gmetoolkit.com www2.myevaluations.com rm.verinform.com mygme.com my.doctorsoncall.com).find{|d|csr.common_name=~Regexp.new(d)}
            options.merge!('days' => days.to_s)
          end
          #ssl.com Sub CA certs
          ssl_com_order(options)
          if is_api_call
            options.merge!('dcvMethod' => dcv_method) if dcv_method
            if dcv_method.blank? || dcv_method=~/email/i
              if dcv_email_addresses && is_ucc?
                options.merge!('dcvEmailAddress' => dcv_email_addresses)
              elsif dcv_email_address
                options.merge!('dcvEmailAddresses' => dcv_email_address)
              end
            end
          elsif !skip_verification?
            if last_sent.dcv_method=="http"
              options.merge!('dcvMethod' => "HTTP_CSR_HASH")
            elsif last_sent.try("is_eligible_to_send?")
              options.merge!('dcvEmailAddress' => last_sent.email_address)
              last_sent.send_dcv! unless last_sent.sent_dcv?
            end
          end
          fill_csr_fields options, certificate_content.registrant
          unless csr.csr_override.blank?
            fill_csr_fields options, csr.csr_override
          end
          if certificate.is_wildcard?
            options.merge!('servers' => server_licenses.to_s || '1')
          end
        end
        if certificate.is_ev?
          certificate_content.tap do |cc|
            options.merge!('joiCountryName'=>(cc.csr.csr_override || cc.registrant).country)
            options.merge!('joiLocalityName'=>(cc.csr.csr_override || cc.registrant).city)
            options.merge!('joiStateOrProvinceName'=>(cc.csr.csr_override || cc.registrant).state)
          end
        end
        if certificate.is_ucc?
          domains=certificate_content.domains.flatten unless certificate_content.domains.blank?
          options.merge!(
              'domainNames'=>domains.blank? ? csr.common_name : ([csr.common_name]+domains).uniq.join(","),
              'primaryDomainName'=>csr.common_name,
              'maxSubjectCNs'=>1
          )
          options.merge!('days' => '1095') if options['days'].to_i > 1095 #Comodo doesn't support more than 3 years
        end
      end
    end
  end

  def csr_ca_api_requests
    certificate_contents.map(&:csr).flatten.compact.map(&:ca_certificate_requests)
  end

  # creates a new external ca order history by deleting the old external order id and requests thus allowing us
  # to start a new history with comodo for an existing ssl.com cert order
  # useful in the event Comodo take forever to make changes to an existing order (and sometimes cannot) so we just create a new one
  # and have the old one refunded
  def reset_ext_ca_order
    certificate_contents.map(&:csr).map(&:sent_success).flatten.compact.uniq.each{|a|a.delete}
    cc=certificate_content
    cc.preferred_reprocessing = false
    cc.save validation: false
  end

  #get the most recent order_number as the one
  def external_order_number
    certificate_contents.map(&:csr).map(&:sent_success).flatten.compact.uniq.first.order_number if
        certificate_contents.map(&:csr) && !certificate_contents.map(&:csr).map(&:sent_success).blank? &&
        certificate_contents.map(&:csr).map(&:sent_success).flatten.compact.uniq.first
    #csr.sent_success.order_number if csr && csr.sent_success
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
    response=[bp, (ssl_account.orders.map(&:billing_profile)-[bp]).shift].compact.each do |bp|
      p "purchase using billing_profile_id==#{bp.id}"
      options={profile: bp, cvv: false}
      new_cert = self.dup
      new_cert.certificate_contents.build
      new_cert.duration=1 #only renew 1 year at a time
      co = setup_certificate_order(renewal_certificate, new_cert)
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

  def ssl_com_order(options)
    if certificate.serial=~/256sslcom/
      prod_code = if certificate.is_ev?
                    403
                  elsif certificate.is_essential_ssl?
                    401
                  else
                    402
                  end
      options.merge!('caCertificateID' => prod_code.to_s)
    end
  end
end
