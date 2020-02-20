# frozen_string_literal: true

# == Schema Information
#
# Table name: certificate_orders
#
#  id                    :integer          not null, primary key
#  amount                :integer
#  auto_renew            :string(255)
#  auto_renew_status     :string(255)
#  ca                    :string(255)
#  expires_at            :datetime
#  ext_customer_ref      :string(255)
#  external_order_number :string(255)
#  is_expired            :boolean
#  is_test               :boolean
#  line_item_qty         :integer
#  nonwildcard_count     :integer
#  notes                 :text(65535)
#  num_domains           :integer
#  ref                   :string(255)
#  request_status        :string(255)
#  server_licenses       :integer
#  validation_type       :string(255)
#  wildcard_count        :integer
#  workflow_state        :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  acme_account_id       :string(255)
#  assignee_id           :integer
#  folder_id             :integer
#  renewal_id            :integer
#  site_seal_id          :integer
#  ssl_account_id        :integer
#  validation_id         :integer
#
# Indexes
#
#  index_certificate_orders_on_3_cols                         (workflow_state,is_expired,is_test)
#  index_certificate_orders_on_3_cols(2)                      (ssl_account_id,workflow_state,id)
#  index_certificate_orders_on_4_cols                         (ssl_account_id,workflow_state,is_test,updated_at)
#  index_certificate_orders_on_acme_account_id                (acme_account_id)
#  index_certificate_orders_on_assignee_id                    (assignee_id)
#  index_certificate_orders_on_created_at                     (created_at)
#  index_certificate_orders_on_folder_id                      (folder_id)
#  index_certificate_orders_on_id_and_ref_and_ssl_account_id  (id,ref,ssl_account_id)
#  index_certificate_orders_on_id_ws_ie_it                    (id,workflow_state,is_expired,is_test)
#  index_certificate_orders_on_is_expired                     (is_expired)
#  index_certificate_orders_on_is_test                        (is_test)
#  index_certificate_orders_on_ref                            (ref)
#  index_certificate_orders_on_renewal_id                     (renewal_id)
#  index_certificate_orders_on_ssl_account_id                 (ssl_account_id)
#  index_certificate_orders_on_test                           (id,is_test)
#  index_certificate_orders_on_validation_id                  (validation_id)
#  index_certificate_orders_on_workflow_state                 (id,workflow_state,is_expired,is_test) UNIQUE
#  index_certificate_orders_on_workflow_state_and_is_expired  (workflow_state,is_expired)
#  index_certificate_orders_on_workflow_state_and_renewal_id  (workflow_state,renewal_id)
#  index_certificate_orders_on_ws_ie_it_ua                    (workflow_state,is_expired,is_test)
#  index_certificate_orders_on_ws_ie_ri                       (workflow_state,is_expired,renewal_id)
#  index_certificate_orders_on_ws_is_ri                       (workflow_state,is_expired,renewal_id)
#  index_certificate_orders_r_eon_n                           (ref,external_order_number,notes)
#  index_certificate_orders_site_seal_id                      (site_seal_id)
#

class CertificateOrder < ApplicationRecord
  extend Memoist
  include V2MigrationProgressAddon
  include Pagable

  acts_as_sellable cents: :amount, currency: false
  belongs_to  :ssl_account, touch: true
  belongs_to  :folder, touch: true
  has_many    :users, through: :ssl_account
  belongs_to  :assignee, class_name: 'User'
  belongs_to  :validation
  has_many    :validation_histories, through: :validation
  belongs_to  :site_seal
  belongs_to :parent, class_name: 'CertificateOrder', foreign_key: :renewal_id
  has_one :renewal, class_name: 'CertificateOrder', foreign_key: :renewal_id, dependent: :destroy # represents a child renewal
  has_many    :renewal_attempts
  has_many    :renewal_notifications
  has_many    :cdns
  has_many :certificate_contents, dependent: :destroy, after_add: Proc.new { |p, _| p.certificate_content(true) }
  has_many    :certificate_names, through: :certificate_contents
  has_one     :locked_recipient, class_name: 'LockedRecipient', as: :contactable, dependent: :destroy
  has_many    :registrants, through: :certificate_contents
  has_many    :locked_registrants, through: :certificate_contents
  has_many    :certificate_contacts, through: :certificate_contents
  has_many    :domain_control_validations, through: :certificate_names
  has_many :csrs, through: :certificate_contents, source: 'csr'
  has_many    :csr_unique_values, through: :csrs
  has_many    :attestation_certificates, through: :certificate_contents
  has_many    :signed_certificates, through: :csrs, source: :signed_certificate do
    def expired
      where{ expiration_date < Date.today }
    end
  end
  has_many :attestation_certificates, through: :certificate_contents do
    def expired
      where{ expiration_date < Date.today }
    end
  end
  has_many    :attestation_issuer_certificates, :through => :certificate_contents
  has_many    :shadow_certificates, :through=>:csrs, class_name: "ShadowSignedCertificate"
  has_many    :ca_certificate_requests, :through=>:csrs
  has_many    :ca_api_requests, :through=>:csrs
  has_many    :sslcom_ca_requests, :through=>:csrs
  has_many    :sub_order_items, :as => :sub_itemable, :dependent => :destroy
  has_many    :product_variant_items, through: :sub_order_items, :dependent => :destroy
  has_many    :orders, :through => :line_items, unscoped: true
  has_many    :other_party_validation_requests, class_name: "OtherPartyValidationRequest", as: :other_party_requestable, dependent: :destroy
  has_many    :ca_retrieve_certificates, as: :api_requestable, dependent: :destroy
  has_many    :ca_mdc_statuses, as: :api_requestable
  has_many    :jois, as: :contactable, class_name: 'Joi' # for SSL.com EV; rw by vetting agents, r by customer
  has_many    :app_reps, as: :contactable, class_name: 'AppRep' # for SSL.com OV and EV; rw by vetting agents, r by customer
  has_many    :physical_tokens
  has_many :url_callbacks, as: :callbackable, through: :certificate_contents
  has_many    :taggings, as: :taggable
  has_many    :tags, through: :taggings
  has_many    :notification_groups_subjects, as: :subjectable
  has_many    :notification_groups, through: :notification_groups_subjects
  has_many    :certificate_order_tokens
  has_many    :certificate_order_managed_csrs, dependent: :destroy
  has_many    :managed_csrs, through: :certificate_order_managed_csrs
  has_many    :certificate_order_domains, dependent: :destroy
  has_many :managed_domains, through: :certificate_order_domains, source: :domain

  accepts_nested_attributes_for :certificate_contents, allow_destroy: false
  attr_accessor :duration, :has_csr

  # the following only apply to api calls
  attr_accessor :certificate_url, :receipt_url, :smart_seal_url, :validation_url, :dcv_method, :dcv_email_address, :dcv_candidate_addresses

  # used to temporarily determine lineitem qty
  attr_accessor :quantity
  preference :payment_order, :string, default: 'normal'
  preference  :certificate_chain, :string

  # if the customer has not used this certificate order with a period of time
  # it becomes expired and invalid
  alias_attribute  :expired, :is_expired

  if Proc.new{ |co|co.migrated_from_v2? }
    preference :v2_product_description, :string, default: 'ssl certificate'
    preference :v2_line_items, :string
  end

  default_scope{ where{ (workflow_state << ['canceled','refunded','charged_back']) & (is_expired != true) }.order(created_at: :desc)}

  scope :with_counts, -> {
    select <<~SQL
      certificate_orders.*,
      (
        SELECT COUNT(certificate_contents.id) FROM certificate_contents
        WHERE certificate_order_id = certificate_orders.id
      ) AS certificate_contents_count
    SQL
  }

  scope :not_test, ->{ where{ (is_test == nil) | (is_test == false) } }

  scope :is_test, ->{ where{ is_test == true } }

  scope :search, lambda { |term, options={}|
    where{ ref =~ '%' + term + '%' }.merge(options)
  }

  scope :with_includes, -> { includes(%i[ssl_account orders validation site_seal]) }

  scope :search_physical_tokens, lambda { |state='new'|
    joins{ physical_tokens }.where{ physical_tokens.workflow_state >> [state.split(',')] } unless state.blank?
  }

  scope :search_signed_certificates, lambda { |term|
    joins{ certificate_contents.csr.signed_certificates }.
      where{ certificate_contents.csr.signed_certificates.common_name =~ "%#{term}%" }
  }

  scope :search_csr, lambda { |term|
    joins{ certificate_contents.csr }.where{ certificate_contents.csr.common_name =~ "%#{term}%" }
  }

  scope :search_assigned, lambda { |term|
    joins{ assignee }.where{ assignee.id == term }
  }

  scope :search_validated_not_assigned, lambda { |term|
    joins{ certificate_contents }.
        joins{ certificate_contents.locked_registrant }.
        where{ (assignee_id == nil ) &
        (certificate_contents.workflow_state == 'validated') &
        (certificate_contents.locked_registrant.email == term)
    }
  }

  scope :search_with_csr, lambda { |term, options={}|
    term ||= ''
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = {common_name: nil, organization: nil, organization_unit: nil, address: nil, state: nil, postal_code: nil,
               subject_alternative_names: nil, locality: nil, country:nil, signature: nil, fingerprint: nil, strength: nil,
               expires_at: nil, created_at: nil, login: nil, email: nil, account_number: nil, product: nil,
               decoded: nil, is_test: nil, order_by_csr: nil, physical_tokens: nil, issued_at: nil, notes: nil,
               ref: nil, external_order_number: nil, status: nil, duration: nil, co_tags: nil, cc_tags: nil,
               folder_ids: nil}
    filters.each{ |fn, fv|
      term.delete_if { |s|s =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1 }
    }
    term = term.empty? ? nil : term.join(' ')
    return nil if [term,*(filters.values)].compact.empty?
    result = not_new
    cc_query = CertificateContent
    keys = filters.map{ |f|f[0] if !f[1].blank? }.compact
    unless term.blank?
      # if 'is_test' and 'order_by_csr' are the only search terms, keep it simple
      sql = %(MATCH (csrs.common_name, csrs.body, csrs.decoded) AGAINST ('#{term}') OR
          MATCH (signed_certificates.common_name, signed_certificates.url, signed_certificates.body,
          signed_certificates.decoded, signed_certificates.ext_customer_ref, signed_certificates.ejbca_username)
          AGAINST ('#{term}') OR
          MATCH (ssl_accounts.acct_number, ssl_accounts.company_name, ssl_accounts.ssl_slug) AGAINST ('#{term}') OR
          MATCH (certificate_orders.ref, certificate_orders.external_order_number, certificate_orders.notes) AGAINST ('#{term}') OR
          MATCH (users.login, users.email) AGAINST ('#{term}')).squish
      result = result.joins{ csrs.outer }.joins{ csrs.outer.signed_certificates.outer }.joins{ ssl_account.outer }.
          joins{ ssl_account.users.outer }.where(sql)
    end
    result = result.joins{ ssl_account.outer } unless (keys & [:account_number]).empty?
    result = result.joins{ ssl_account.users.outer } unless (keys & [:login, :email]).empty?
    cc_query = (cc_query || CertificateContent).joins{ csrs } unless
        (keys & [:country, :strength, :common_name, :organization, :organization_unit, :state,
                :subject_alternative_names, :locality, :decoded]).empty?
    cc_query = (cc_query || CertificateContent).joins{ csr.signed_certificates.outer } unless
        (keys & [:country, :strength, :postal_code, :signature, :fingerprint, :expires_at, :created_at, :issued_at,
                 :common_name, :organization, :organization_unit, :state, :subject_alternative_names, :locality,
                 :decoded, :address]).empty?
    %w(is_test).each do |field|
      query = filters[field.to_sym]
      if query.try('true?')
        result = result.send(field)
      elsif query.try('false?')
        result = result.not_test
      end
    end
    %w(order_by_csr).each do |field|
      query = filters[field.to_sym]
      result = result.send(field) if query.try('true?')
    end
    %w(physical_tokens).each do |field|
      query = filters[field.to_sym]
      result = result.search_physical_tokens(query) if query
    end
    %w(postal_code signature fingerprint).each do |field|
      query = filters[field.to_sym]
      cc_query = cc_query.where{
        (csr.signed_certificates.send(field.to_sym) =~ "%#{query}%")} if query
    end
    %w(product).each do |field|
      query = filters[field.to_sym]
      result = result.filter_by(query) if query
    end
    %w(duration).each do |field|
      query = filters[field.to_sym]
      result = result.filter_by_duration(query) if query
    end
    %w(ref).each do |field|
      query = filters[field.to_sym]
      if query
        result = result.where{ ref >> query.split(',') }
        cc_query = cc_query.where{ ref >> query.split(',') }
      end
    end
    %w(country strength).each do |field|
      query = filters[field.to_sym]
      cc_query = cc_query.where{
        (csr.signed_certificates.send(field.to_sym) >> query.split(',')) |
            (csrs.send(field.to_sym) >> query.split(','))} if query
    end
    %w(status).each do |field|
      query = filters[field.to_sym]
      if query
        cc_query = cc_query.where{ workflow_state >> query.split(',') }
      end
    end
    %w(common_name organization organization_unit state subject_alternative_names locality decoded).each do |field|
      query = filters[field.to_sym]
      cc_query = cc_query.where{
        (csr.signed_certificates.send(field.to_sym) =~ "%#{query}%") |
            (csrs.send(field.to_sym) =~ "%#{query}%") } if query
    end
    %w(address).each do |field|
      query = filters[field.to_sym]
      cc_query = cc_query.where{
        (csr.signed_certificates.address1 =~ "%#{query}%") |
        (csr.signed_certificates.address2 =~ "%#{query}%")} if query
    end
    %w(login email).each do |field|
      query = filters[field.to_sym]
      result = result.where{
        (ssl_account.users.send(field.to_sym) =~ "%#{query}%")} if query
    end
    %w[account_number].each do |_field|
      query = filters[:acct_number]
      result = result.where{ (ssl_account.send(:acct_number) =~ "%#{query}%") } if query
    end
    %w(expires_at created_at issued_at).each do |field|
      query = filters[field.to_sym]
      if query
        query = query.split('-')
        start = Date.strptime query[0], '%m/%d/%Y'
        finish = query[1] ? Date.strptime(query[1], '%m/%d/%Y') : start + 1.day
        if(field == 'expires_at')
          cc_query = cc_query.where{ (csr.signed_certificates.expiration_date >> (start..finish)) }
        elsif(field == 'issued_at')
          cc_query = cc_query.where{ (csr.signed_certificates.created_at >> (start..finish)) }
        else
          result = result.where{ created_at >> (start..finish) }
        end
      end
    end
    %w(co_tags).each do |field|
      query = filters[field.to_sym]
      if query
        @result_prior_co_tags = result
        result = result.joins(:tags).where(tags: {name: query.split(',')})
      end
    end
    %w(cc_tags).each do |field|
      query = filters[field.to_sym]
      if query
        cc_results = (@result_prior_co_tags || result)
          .joins(certificate_contents: [:tags]).where(tags: {name: query.split(',')})

        result = if @result_prior_co_tags.nil?
          cc_results
        else
          # includes tags in BOTH certificate orders and certificate contents tags, not a union
          CertificateOrder.where(id: (result + cc_results).map(&:id).uniq)
        end
      end
    end
    %w(folder_ids).each do |field|
      query = filters[field.to_sym]
      result = result.where(folder_id: query.split(',')) if query
    end
    if cc_query != CertificateContent
      ids = cc_query.pluck(:id).uniq
      unless ids.empty?
        result.joins{ certificate_contents }.where{ certificate_contents.id >> ids }
      else
        result.uniq
      end
    else
      result.uniq
    end
  }

  # scope :reprocessing, lambda {
  #   cids=Preference.select("owner_id").joins{owner(CertificateContent)}.
  #       where{(name=="reprocessing") & (value==1)}.map(&:owner_id)
  #   joins{certificate_contents.csr}.where{certificate_contents.id >> cids}.order("csrs.updated_at asc")
  # }

  # more elegant but needs to be refined. Too slow
  # scope :reprocessing1, lambda {
  #   cids=Preference.joins{owner(CertificateContent)}.
  #       where{(name=="reprocessing") & (value==1)}.select{owner_id}
  #   joins{certificate_contents.csr}.where{certificate_contents.id.in(cids)}.order("csrs.updated_at asc")
  # }
  #
  scope :order_by_csr, lambda {
    joins{ certificate_contents.csr.outer }.order('csrs.created_at desc') #.uniq #- breaks order by csr
  }

  scope :filter_by, lambda { |term|
    terms = term.split(',').map{ |t|t + '%' }
    joins{ sub_order_items.product_variant_item.product_variant_group.
      variantable(Certificate)}.where(('certificates.product like ?@' * terms.count).split('@').join(' OR '), *terms)
  }

  scope :filter_by_duration, lambda { |term|
    joins{ certificate_contents }.where{ certificate_contents.duration >> term.split(',') }
  }

  scope :unvalidated, ->{ joins(:certificate_contents).where{ (is_expired == false) &
    (certificate_contents.workflow_state >> ['pending_validation', 'contacts_provided'])}.
      order('certificate_contents.updated_at asc')}

  scope :not_csr_blank, ->{ joins{ certificate_contents.csr }.where{ certificate_contents.csr.id != nil } }

  scope :incomplete, ->{ not_test.joins(:certificate_contents).where{ (is_expired == false) &
    (certificate_contents.workflow_state >> ['csr_submitted', 'info_provided', 'contacts_provided'])}.
      order('certificate_contents.updated_at asc')}

  scope :pending, ->{ not_test.joins(:certificate_contents).where{ certificate_contents.workflow_state >>
      ['pending_validation', 'validated']}.order('certificate_contents.updated_at asc')}

  scope :has_csr, ->{ not_test.joins(:certificate_contents).where{ (workflow_state == 'paid') &
    (certificate_contents.signing_request != '')}.order('certificate_contents.updated_at asc')}

  scope :credits, ->{ not_test.joins(:certificate_contents).where({workflow_state: 'paid'} & {is_expired: false} &
    {certificate_contents: {workflow_state: 'new'}})} # and not new

  #new certificate orders are the ones still in the shopping cart
  scope :not_new, lambda { |options=nil|
    if options && options.has_key?(:includes)
      includes = method(:includes).call(options[:includes])
    end
    (includes || self).where{ workflow_state << ['new'] }.uniq
  }

  scope :is_new, lambda { where{ workflow_state >> ['new'] }.uniq }

  scope :unrenewed, ->{ not_new.where(renewal_id: nil) }

  scope :renewed, ->{ not_new.where{ :renewal_id != nil } }

  scope :nonfree, ->{ not_new.where(:amount.gt => 0) }

  scope :free, ->{ not_new.where(amount: 0) }

  scope :unused_credits, ->{
    unused = joins{}
    where{ (workflow_state == 'paid') & (is_expired == false) & (id << unused.joins{ certificate_contents.csr.signed_certificates.outer }.pluck(id).uniq) }
  }

  scope :used_credits, ->{
    unused = where{ (workflow_state == 'paid') & (is_expired == false) }
    where{ id >> unused.joins{ certificate_contents.csr.signed_certificates.outer }.pluck(id) }
  }

  scope :unflagged_expired_credits, ->{ unused_credits.
      where{ created_at < Settings.cert_expiration_threshold_days.to_i.days.ago }}

  scope :unused_purchased_credits, ->{ unused_credits.where{ amount > 0 } }

  scope :unused_free_credits, ->{ unused_credits.where{ amount == 0 } }

  scope :falsely_expired, -> { unscoped.where{ (workflow_state == 'paid') & (is_expired == true) &
      (external_order_number != nil)}}

  scope :range, lambda{ |start, finish|
    if start.is_a?(String)
      (s = start =~ /\// ? '%m/%d/%Y' : '%m-%d-%Y')
      start = Date.strptime(start, s)
    end
    if finish.is_a?(String)
      (f = finish =~ /\// ? '%m/%d/%Y' : '%m-%d-%Y')
      finish = Date.strptime(finish, f)
    end
    where{ created_at >> (start..finish) }
  } do

    def amount
      self.nonfree.sum(:amount) * 0.01
    end
  end

  FULL = 'full'
  EXPRESS = 'express'
  PREPAID_FULL = 'prepaid_full'
  PREPAID_EXPRESS = 'prepaid_express'
  VERIFICATION_STEP = 'Perform Validation'
  CLIENT_SMIME_VALIDATE = 'client_smime_validate'
  CLIENT_SMIME_VALIDATED = 'client_smime_validated'
  CLIENT_SMIME_VALIDATED_SHORT = 'client_smime_validated_short'

  FULL_SIGNUP_PROCESS = {label: FULL, pages: %W(Submit\ CSR Payment
    Registrant Contacts #{VERIFICATION_STEP} Complete)}
  EXPRESS_SIGNUP_PROCESS = {label: EXPRESS,
                            pages: FULL_SIGNUP_PROCESS[:pages] - %w(Contacts)}
  PREPAID_FULL_SIGNUP_PROCESS = {label: PREPAID_FULL,
                                 pages: FULL_SIGNUP_PROCESS[:pages] - %w(Payment)}
  NO_CSR_SIGNUP_PROCESS = {label: PREPAID_FULL,
                           pages: PREPAID_FULL_SIGNUP_PROCESS[:pages] - %w(Submit\ CSR)}
  PREPAID_EXPRESS_SIGNUP_PROCESS = {label: PREPAID_EXPRESS,
                                    pages: EXPRESS_SIGNUP_PROCESS[:pages] - %w(Payment)}
  REPROCES_SIGNUP_W_PAYMENT = {label: FULL,
    pages: FULL_SIGNUP_PROCESS[:pages]}
  REPROCES_SIGNUP_W_INVOICE = {label: PREPAID_EXPRESS,
    pages: FULL_SIGNUP_PROCESS[:pages] - %w(Payment)}
  CLIENT_SMIME_FULL = {
    label: CLIENT_SMIME_VALIDATE,
    pages: ['Registrant', 'Recipient', 'Upload Documents', 'Complete']
  }
  CLIENT_SMIME_IV_VALIDATE = {
    label: CLIENT_SMIME_VALIDATE,
    pages: ['Recipient', 'Upload Documents', 'Complete']
  }
  CLIENT_SMIME_IV_VALIDATED = {
    label: CLIENT_SMIME_VALIDATE,
    pages: ['Recipient', 'Complete']
  }
  CLIENT_SMIME_NO_DOCS = {
    label: CLIENT_SMIME_VALIDATED,
    pages: ['Registrant', 'Recipient', 'Complete']
  }
  CLIENT_SMIME_NO_IV_OV = {
    label: CLIENT_SMIME_VALIDATED_SHORT,
    pages: ['Recipient', 'Complete']
  }

  CSR_SUBMITTED = :csr_submitted
  INFO_PROVIDED = :info_provided
  REPROCESS_REQUESTED = :reprocess_requested
  CONTACTS_PROVIDED = :contacts_provided

  CA_CERTIFICATES = {SSLcomSHA2: 'SSLcomSHA2'}

  STATUS = {CSR_SUBMITTED => 'info required',
            INFO_PROVIDED => 'contacts required',
            REPROCESS_REQUESTED => 'csr required',
            CONTACTS_PROVIDED => 'validation required'}

  RENEWING = 'renewing'
  REPROCESSING = 'reprocessing'
  RECERTS = [RENEWING, REPROCESSING]
  RENEWAL_DATE_CUTOFF = 45.days.ago
  RENEWAL_DATE_RANGE = 45.days.from_now
  ID_AND_TIMESTAMP = ['id', 'created_at', 'updated_at']
  COMODO_SSL_MAX_DURATION = 730
  SSL_MAX_DURATION = 820
  EV_SSL_MAX_DURATION = 730
  CS_MAX_DURATION = 1095
  CLIENT_MAX_DURATION = 1095
  SMIME_MAX_DURATION = 1095
  TS_MAX_DURATION = 4106

  # changed for the migration
  # unless MIGRATING_FROM_LEGACY
  #   validates :certificate, presence: true
  # else
  #   validates :certificate, presence: true, :unless=>Proc.new {|co|
  #     !co.orders.last.nil? && (co.orders.last.preferred_migrated_from_v2 == true)}
  # end

  before_create do |co|
    default_folder = Folder.find_by(default: true, ssl_account_id: ssl_account_id)
    co.folder_id = default_folder.id if default_folder
    co.ca = CA_CERTIFICATES[:SSLcomSHA2]
    co.is_expired = false
    co.ref = 'co-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
    v = co.create_validation
    co.preferred_certificate_chain = co&.certificate&.preferred_certificate_chain
    co&.certificate&.validation_rulings&.each do |cvrl|
      vrl = cvrl.dup
      vrl.status = ValidationRuling::WAITING_FOR_DOCS
      vrl.workflow_state = 'new'
      v.validation_rulings << vrl
    end
    co.site_seal = SiteSeal.create
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
      event :pay, transitions_to: :paid do |payment|
        halt unless payment
        post_process_csr unless is_prepaid?
      end
      event :reject, transitions_to: :rejected
      event :cancel, transitions_to: :canceled
    end

    state :paid do
      event :cancel, transitions_to: :canceled
      event :reject, transitions_to: :rejected
      event :refund, transitions_to: :refunded
      event :charge_back, transitions_to: :charged_back
      event :start_over, transitions_to: :paid do |complete=false|
        if self.certificate_contents.count > 1
          cc = self.certificate_contents.last
          cc.preserve_certificate_contacts
          cc.delete
        else
          duration = self.certificate_content.duration
          temp_cc = self.certificate_contents.create(duration: duration)
          # Do not delete the last one
          (self.certificate_contents - [temp_cc]).each do |cc|
            cc.delete if ((cc.csr or cc.csr.try(:signed_certificate)) || complete)
          end
        end
      end
    end

    state :canceled do
      event :uncancel, transitions_to: :paid
      event :unrefund, transitions_to: :canceled
      event :refund, transitions_to: :refunded
      event :reject, transitions_to: :rejected
      event :charge_back, transitions_to: :charged_back
      event :cancel, transitions_to: :canceled
    end

    state :refunded do #only refund a canceled order
      event :unrefund, transitions_to: :paid
      event :reject, transitions_to: :rejected
      event :charge_back, transitions_to: :charged_back
    end

    state :charged_back

    state :rejected do #only refund a canceled order
      event :cancel, transitions_to: :canceled
      event :unreject, transitions_to: :paid
      event :refund, transitions_to: :refunded
    end
  end

  def locked_recipient_subject_dn
    dn = []
    if get_recipient
      dn << "CN=#{[locked_recipient.first_name,locked_recipient.last_name].join(" ").strip}"
      dn << "emailAddress=#{locked_recipient.email}"

      dn.map{ |d|d.gsub(/\\/,'\\\\').gsub(',','\,') }.join(',')
    end
  end

  def get_recipient
    recipient = locked_recipient
    if locked_recipient.nil? && assignee
      recipient = LockedRecipient.create_for_co(self)
    end
    recipient
  end

  def get_audit_logs
    SystemAudit.where(
        '(target_id = ? AND target_type = ?) OR (target_id IN (?) AND target_type = ?)',
          id, 'CertificateOrder', line_items.ids, 'LineItem'
    ).order('created_at desc')
  end


  def domains_adjust_billing?
    certificate.is_ucc? && (certificate.is_premium_ssl? != 0) &&
    orders.count > 0 && orders.first.persisted?
  end

  # Prorated pricing for single domain for ucc certificate,
  # used in calculating reprocessing amount for additional domains.
  def ucc_prorated_domain(type, reseller_tier=nil)
    if certificate.is_ucc?
      tiers = ucc_duration_amounts(certificate_duration(:years).to_i, reseller_tier)
      domain_amount = (type == :wildcard && !certificate.is_ev?) ? tiers['tier_3'] : tiers['tier_2']
      total_duration = certificate_duration(:days)
      domain_amount - ( (used_days / total_duration) * domain_amount )
    end
  end

  # Get pricing for each tier for a given duration,
  # used in calculating reprocessing amount for additional domains.
  def ucc_duration_amounts(years=1, reseller_tier=nil)
    if certificate.is_ucc?
      durations = {}
      i = years - 1
      cur_certificate = certificate

      unless reseller_tier.blank?
        ssl_tier = ssl_account.reseller_tier_label
        unless ssl_tier.blank?
          reseller_tier = reseller_tier.include?(ssl_tier) ? reseller_tier : "#{ssl_tier}tr"
        end
        cur_certificate = Certificate.tiered_products(/\-?#{reseller_tier}/)
          .find { |c| c.title == certificate.title }
        cur_certificate = certificate if cur_certificate.nil?
      end

      cur_certificate.num_domain_tiers.times do |j|
        durations["tier_#{j + 1}"] = (cur_certificate.items_by_domains(true)[i][j].price * ( (j == 0) ? 3 : 1 )).cents
      end
      durations
    end
  end

  def ucc_get_max_counts(certificate_content=nil)
    max_wildcard_count    = get_reprocess_max_wildcard(certificate_content).count
    max_nonwildcard_count = get_reprocess_max_nonwildcard(certificate_content).count

    # check against counts of certificate's initial purchase
    if !wildcard_count.blank? && (wildcard_count > max_wildcard_count)
      max_wildcard_count = wildcard_count
    end
    if !nonwildcard_count.blank? && (nonwildcard_count > max_nonwildcard_count)
      max_nonwildcard_count = nonwildcard_count
    end

    {wildcard_count: max_wildcard_count, nonwildcard_count: max_nonwildcard_count}
  end

  def ucc_prorated_amount(certificate_content, reseller_tier=nil)
    max = ucc_get_max_counts(certificate_content)
    max_wildcard_count = max[:wildcard_count]
    max_nonwildcard_count = max[:nonwildcard_count]

    # make sure NOT to charge for tier 1 domains (3 total)
    max_nonwildcard_count = (max_nonwildcard_count < 3) ? 3 : max_nonwildcard_count
    nonwildcard_cost      = ucc_prorated_domain(:nonwildcard, reseller_tier)
    wildcard_cost         = ucc_prorated_domain(:wildcard, reseller_tier)
    new_nonwildcard_count = 0
    new_wildcard_count    = 0
    certificate_content.domains.each do |name|
      name.include?('*') ? (new_wildcard_count += 1) : (new_nonwildcard_count += 1)
    end
    addt_nonwildcard = new_nonwildcard_count - max_nonwildcard_count
    addt_wildcard    = new_wildcard_count - max_wildcard_count
    addt_nonwildcard = (addt_nonwildcard < 0) ? 0 : addt_nonwildcard
    addt_wildcard    = (addt_wildcard < 0) ? 0 : addt_wildcard
    (addt_nonwildcard * nonwildcard_cost) + (addt_wildcard * wildcard_cost)
  end

  # Retrieve certificate contents signed certificate (subject_alternative_names).
  # IF certificate content is passed, THEN consider ONLY certificate
  # contents prior to passed certificate content.
  def get_reprocess_cc_domains(cc_id=nil)
    cur_domains = []
    if certificate_contents.any?
      cur_domains = certificate_contents.includes(:signed_certificates).where(workflow_state: 'issued')
      end_target  = certificate_contents.find_by(id: cc_id) unless cc_id.nil?
      if end_target
        cur_domains = cur_domains.where(
          created_at: certificate_contents.first.created_at...end_target.created_at
        )
      end
    end
    if cur_domains.any?
      cur_domains = cur_domains.map(&:signed_certificates).compact
        .reject{ |sc| sc.empty? }.flatten.map(&:subject_alternative_names)
    end

    if cur_domains.empty? && (renew_billing? || domains_adjust_billing?)
      cur_domains = certificate_contents.map(&:domains)
    end
    cur_domains
  end
  memoize :get_reprocess_cc_domains

  def get_reprocess_max_nonwildcard(cc_id=nil)
    max  = 0
    list = []
    get_reprocess_cc_domains(cc_id).each do |arr|
      cur_max = arr.map { |d| d if !d.include?('*') }.compact
      if cur_max.count > max
        max  = cur_max.count
        list = cur_max
      end
    end
    list
  end

  def get_reprocess_max_wildcard(cc_id=nil)
    max  = 0
    list = []
    get_reprocess_cc_domains(cc_id).each do |arr|
      cur_max = arr.map { |d| d if d.include?('*') }.compact
      if cur_max.count > max
        max  = cur_max.count
        list = cur_max
      end
    end
    list
  end

  def add_reproces_order(target_order)
    target_order.save unless target_order.persisted?
    target_order.line_items.destroy_all
    line_items.create(order_id: target_order.id, cents: target_order.cents, amount: target_order.amount, currency: 'USD') if target_order.valid?
    target_order.touch # clear cache
    touch
  end

  def certificate
    if new_record?
      sub_order_items[0].product_variant_item.certificate if sub_order_items[0]&.product_variant_item
    else
      Certificate.unscoped.find_by_id(Rails.cache.fetch("#{cache_key}/certificate") do
        sub_order_items[0].product_variant_item.cached_certificate_id if sub_order_items[0]&.product_variant_item
      end)
    end
  end
  memoize :certificate

  def signed_certificate
    signed_certificates.order(:created_at).first
  end

  def attestation_certificate
    attestation_certificates.order(:created_at).last
  end

  def attestation_issuer_certificate
    attestation_issuer_certificates.order(:created_at).last
  end

  def comodo_ca_id
    (signed_certificate || certificate).comodo_ca_id
  end

  # find the ratio remaining on the cert ie (today-effective_date/expiration_date-effective_date)
  def duration_remaining(options={duration: :order})
    remaining_days(options) / total_days(options)
  end

  def used_days(options={round: false})
    if !signed_certificates.try('empty?'.to_sym)
      sum = (Time.now - (signed_certificates.sort{ |a,b|a.created_at.to_i <=> b.created_at.to_i }.first.effective_date ||
          self.created_at))
      (options[:round] ? sum.round : sum) / 1.day
    else
      0
    end
  end

  def remaining_days(options={round: false, duration: :order})
    tot, used = total_days(options), used_days(options)
    if tot && used && tot > used
      days = total_days(options) - used_days(options)
      (options[:round] ? days.round : days)
    else
      0
    end
  end

  def signed_certificate_duration_delta
    remaining_days - remaining_days(duration: :actual)
  end

  def unchain_comodo
    update_column(:external_order_number, nil) unless external_order_number.blank?
    if certificate_content.ca_id.blank?
      certificate_content.add_ca(ssl_account)
      certificate_content.save
    end
  end

  # :actual is based on the duration of the signed cert, :order is the duration based on the certificate order
  def total_days(options={round: false, duration: :order})
    if options[:duration] == :actual
      unless signed_certificates.empty?
        sum = (signed_certificates.sort{ |a,b|a.created_at.to_i <=> b.created_at.to_i }.last.expiration_date -
            signed_certificates.sort{ |a,b|a.created_at.to_i <=> b.created_at.to_i }.first.effective_date)
        (options[:round] ? sum.round : sum) / 1.day
      else
        0
      end
    else
      certificate_duration(:days)
    end
  end

  # unit can be :days or :years
  def certificate_duration(unit=:as_is)
    Rails.cache.fetch("#{cache_key}/certificate_duration/#{unit.to_s}", expires_in: 24.hours) do
      years = if migrated_from_v2? && !preferred_v2_line_items.blank?
              preferred_v2_line_items.split('|').detect{ |item|
                item =~ /years?/i || item =~ /days?/i}.scan(/\d+.+?(?:ear|ay)s?/).last
            else
              unless certificate.is_ucc?
                sub_order_items.includes(:product_variant_item).map(&:product_variant_item).detect{ |item|item.is_duration? }.try(:description)
              else
                d = sub_order_items.includes(:product_variant_item).map(&:product_variant_item).detect{ |item|item.is_domain? }.try(:description)
                unless d.blank?
                  d =~ /(\d years?)/i
                  $1
                end
              end
            end
      if unit == :years
        years =~ /\A(\d+)/
        $1
      elsif unit == :days
        case years.gsub(/[^\d]+/,'').to_i
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
        when 6,7,8,9,10
          years.gsub(/[^\d]+/,'').to_i * 365
        else # assume days
          years.gsub(/[^\d]+/,'').to_i if years.include?('day')
        end
      elsif [:comodo_api,:sslcom_api].include? unit
        case years.gsub(/[^\d]+/,'').to_i
        when 1
          365
        when 2
          730
        when 90 #trial
          90
        when 30 #trial
          30
        else #no ssl can go beyond 39 months. 36 months to make adding 1 or 2 years later easier
          unit == :comodo_api ? COMODO_SSL_MAX_DURATION : SSL_MAX_DURATION
        end
      else
        years
      end
    end
  end
  memoize :certificate_duration

  def renewal_certificate
    if migrated_from_v2?
      Certificate.map_to_legacy(preferred_v2_product_description, 'renew')
    elsif certificate.is_free?
      Certificate.for_sale.find_by_product 'basicssl'
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
    extract = ->{
      if certificate.is_ucc?
        year = sub_order_items.map(&:product_variant_item).detect(&:is_domain?)
      else
        year = sub_order_items.map(&:product_variant_item).detect(&:is_duration?)
      end
      year.blank? ? '' : (year.value.to_i < 365 ? "#{year.value.to_i} Days" :
                              "#{year.value.to_i / 365} Year") + " #{certificate.title}"}
    if new_record?
      extract.call
    else
      Rails.cache.fetch("#{cache_key}/description") do
        extract.call
      end
    end
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
    sub_order_items[0].product_variant_item = pvi
    sub_order_items[0].amount = amount
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
  memoize 'migrated_from_v2?'.to_sym

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

  def skip_contacts_step?
    return false if certificate_contents.count == 1
    if certificate && certificate.is_smime_or_client?
      true
    elsif Contact.optional_contacts?
      if signed_certificate.try('is_dv?'.to_sym) && Settings.exempt_dv_contacts
        true
      else
        certificate_contents.includes(:certificate_contacts).map(&:certificate_contacts).flatten.any?
      end
    else
      roles = co.certificate_contacts.includes(:roles).map(&:roles).flatten.uniq
      req_roles = CertificateContent::CONTACT_ROLES
      (roles & req_roles).count == req_roles.count
    end
  end

  def order_status
    if is_ev?
      'waiting for documents'
    end
  end

  def prepaid_signup_process(cert=certificate)
    if cert.admin_submit_csr?
      NO_CSR_SIGNUP_PROCESS
    elsif ssl_account && ssl_account.has_role?('reseller')
      unless cert.is_ev?
        PREPAID_EXPRESS_SIGNUP_PROCESS
      else
        PREPAID_FULL_SIGNUP_PROCESS
      end
    elsif cert.is_client?
      PREPAID_EXPRESS_SIGNUP_PROCESS
    else
      PREPAID_FULL_SIGNUP_PROCESS
    end
  end

  def iv_validated?
    if get_recipient
      iv_exists = get_team_iv
      iv_exists && iv_exists.validated?
    else
      false
    end
  end

  def ov_validated?
    locked_registrant && locked_registrant.validated?
  end

  def iv_ov_validated?
    iv_validated? && ov_validated?
  end

  def smime_client_process
    return CLIENT_SMIME_NO_DOCS if certificate.nil?
    registrant_types = certificate.client_smime_validations

    if registrant_types == 'iv_ov'
      iv_ov_validated? ? CLIENT_SMIME_NO_DOCS : CLIENT_SMIME_FULL
    elsif registrant_types == 'iv'
      (!iv_validated? or self.certificate.is_client_pro?) ? CLIENT_SMIME_IV_VALIDATE : CLIENT_SMIME_IV_VALIDATED
    else
      CLIENT_SMIME_NO_IV_OV
    end
  end

  def get_team_iv(for_assignee=nil)
    recipient = for_assignee ? assignee : get_recipient
    if recipient
      ssl_account.individual_validations.find_by(
        user_id: (recipient.is_a?(User) ? recipient.id : recipient.user_id)
      )
    end
  end

  def get_download_cert_email
    if certificate.is_smime_or_client?
      get_team_iv.email
    else
      certificate_content.locked_registrant.email
    end
  end

  def get_download_cert_salutation
    if certificate.is_smime_or_client?
      [get_team_iv.first_name, get_team_iv.last_name].join(' ')
    else
      [locked_registrant.first_name, locked_registrant.last_name].join(' ')
    end
  end

  def copy_iv_ov_validation_history(type='iv')
    iv_exists = get_team_iv

    if get_recipient && iv_exists && iv_exists.validation_histories.any?
      new_vh = iv_exists.validation_histories - validation.validation_histories
      if locked_recipient
        locked_recipient.validation_histories << new_vh
      end
      validation.validation_histories << new_vh
    end

    if type == 'iv_ov' && locked_registrant &&
      locked_registrant.validation_histories.any?
      new_vh = locked_registrant.validation_histories - validation.validation_histories
      validation.validation_histories << new_vh
    end
  end

  def can_validate_ov?(current_user)
    sysadmin = current_user.is_system_admins?
    acct_admins = current_user.is_owner? || current_user.is_account_admin?
    acct_admins_can = !certificate_content.validated? && acct_admins && ov_validated?

    (certificate.is_smime_or_client? && ( sysadmin || acct_admins_can )) ||
    ((certificate.is_ov? or certificate.is_ev?) && sysadmin)
  end

  def reprocess_ucc_process
    ssl_account.invoice_required? ? REPROCES_SIGNUP_W_INVOICE : REPROCES_SIGNUP_W_PAYMENT
  end

  def express_signup?
    !signup_process[:label].scan(EXPRESS).blank?
  end

  def express_validation?
    validation.validation_rulings.detect(&:new?) &&
      !signup_process[:label].scan(EXPRESS).blank?
  end

  def certificate_content
    certificate_contents.last
  end
  memoize :certificate_content

  def certificate_order_token
    certificate_order_tokens.last
  end

  def generate_certificate_order_token
    certificate_order_tokens.where(status: nil).last
  end

  def phone_verified?
    return false if locked_registrant.blank?
    certificate_order_tokens.where(
        status: CertificateOrderToken::DONE_STATUS,
        phone_number: locked_registrant.country_code.blank? ?
                          ('+1-' + locked_registrant.phone) :
                          ('+' + locked_registrant.country_code + '-' + locked_registrant.phone)

    ).first
  end

  def registrant
    certificate_content.registrant
  end

  def locked_registrant
    certificate_content.locked_registrant
  end

  def csr
    certificate_content.csr
  end

  def most_recent_csr
    csrs.last || parent.try(:most_recent_csr)
  end

  def effective_date
    certificate_content.try('csr').try('signed_certificate').try('effective_date')
  end

  def expiration_date
    certificate_content.csr.signed_certificate.expiration_date
  end

  def is_expired_credit?
    is_expired? && certificate_content.new? && created_at < 6.months.ago
  end

  def subject
    Rails.cache.fetch("#{cache_key}/subject") do
      csr = csrs.last
      return '' if csr.blank?
      if certificate_content.issued?
        csr.signed_certificates.last.try(:common_name)
      else
        certificate_content.certificate_names.where{ is_common_name == true }.last.try(:name) || csr.try(:common_name) || ''
      end
    end || ''
  end
  alias :common_name :subject
  memoize :subject

  def display_subject
    csr = csrs.last
    return if csr.blank?
    last_signed_certificate = csr.signed_certificates.last
    names = last_signed_certificate.subject_alternative_names unless last_signed_certificate.blank?
    names = names.join(', ') unless names.blank?
    names || last_signed_certificate.try(:common_name) || csr.common_name
  end
  memoize :display_subject

  def domains
    if certificate_contents.first.domains.kind_of?(Array)
      certificate_contents.first.domains.flatten
    else
      certificate_contents.first.domains
    end
  end

  def revoke!(reason, owner=nil)
    SystemAudit.create(owner: owner, target: self, notes: reason, action: 'revocation')
    unless self.external_order_number.blank?
      OrderNotifier.request_comodo_refund('refunds@comodo.com', self.external_order_number, reason).deliver
      OrderNotifier.request_comodo_refund('support@ssl.com', self.external_order_number, reason, 'noreply@ssl.com').deliver
      ComodoApi.revoke_ssl(certificate_order: self, refund_reason: reason)
    end
    if self.notes =~ /DV#(\d+)/
      OrderNotifier.request_comodo_refund('refunds@comodo.com', $1, reason).deliver
      OrderNotifier.request_comodo_refund('support@ssl.com', $1, reason, 'noreply@ssl.com').deliver
      ComodoApi.revoke_ssl(refund_reason: reason, external_order_number: $1)
    end
    signed_certificates.each do |sc|
      sc.revoke!(reason) # this will result in redundant calls, but will catch all signed certificates under this order
      cc = sc.certificate_content
      cc.revoke! if cc and !cc.revoked?
    end
  end

  def wildcard_domains
    domains.find_all{ |d|d =~ /\A\*\./ } unless domains.blank?
  end

  def nonwildcard_domains
    domains - nonwildcard_domains unless domains.blank?
  end

  # count of domains bought
  # type can be 'wildcard', 'all'
  def purchased_domains(type='nonwildcard')
    Rails.cache.fetch("#{cache_key}/purchased_domains/#{type.to_s if type}") do
      soid = sub_order_items.find_all{ |item|item.
          product_variant_item.is_domain?}
      case type
      when 'all'
        soid.sum(&:quantity)
      when 'wildcard'
        soid.find_all{ |item|item.product_variant_item.serial =~ /wcdm/ }.sum(&:quantity)
      when 'nonwildcard'
        soid.sum(:quantity) - soid.find_all{ |item|item.product_variant_item.serial =~ /wcdm/ }.sum(&:quantity)
      end
    end
  end
  memoize :purchased_domains

  def order
    orders.last
  end

  def clean_up_mappings(friendly_name)
    cac = certificate.cas_certificates.select{ |c|c.ca.friendly_name =~ Regexp.new(friendly_name) }
    certificate.cas_certificates.where{ id << cac.map(&:id) }.delete_all
    # test
    # certificate.cas.ssl_account_or_general_default(ssl_account)
  end

  # SSL.com chained Root call
  # DRY this up with ValidationsController#new
  def domains_validated?(options={other_dcvs_satisfy_domain: true})
    return true if certificate_content.all_domains_validated?
    if options[:other_dcvs_satisfy_domain]
      ssl_account.other_dcvs_satisfy_domain(certificate_content.certificate_names.unvalidated.all,false)
      certificate_content.all_domains_validated?
    end
  end

  def caa_validated?
    Settings.enable_caa || true
  end

  def to_param
    ref
  end

  def apply_for_certificate(options={})
    # set allow_multiple_certs_per_content to true when manually requesting a new signed certificate which can result
    # in several signed_certificates belonging to the same csr thus certificate_content
    (return false if !certificate_content.signed_certificate.blank? or
        certificate_content.preferred_pending_issuance? or
        !certificate_content.
            preferred_process_pending_server_certificates?) unless options[:allow_multiple_certs_per_content]
    if [Ca::CERTLOCK_CA,Ca::SSLCOM_CA,Ca::MANAGEMENT_CA].include?(options[:ca]) or certificate_content.ca_id or
        !options[:mapping].blank?
      if !certificate_content.infringement.empty? # possible trademark problems
        OrderNotifier.potential_trademark(Settings.notify_address, self, certificate_content.infringement).deliver_now
      elsif !certificate.is_server? or (domains_validated? and caa_validated?)
        # # queue this job due to CAA lookups
        # if certificate_names.count > 10 and not options[:mapping].try(:profile_name)=~/EV/
        #   unless certificate_content.preferred_pending_issuance?
        #     SslcomCaApi.delay.apply_for_certificate(self, options)
        #     certificate_content.pend_issuance!
        #   end
        # else
          SslcomCaApi.apply_for_certificate(self, options)
        # end
      end
    else
      ComodoApi.apply_for_certificate(self, options) if ca_name == 'comodo'
    end if remaining_days > 0
  end

  def retrieve_ca_cert(email_customer=true)
    if external_order_number && certificate_content.ca.blank? &&
        !ca_certificate_requests.empty? && ca_certificate_requests.first.success? && !rejected?
      retrieve = ComodoApi.collect_ssl(self)
      if retrieve.response_code == 2
        csr.signed_certificates.create(body: retrieve.certificate, email_customer: email_customer)
        self.orphaned_certificate_contents remove: true
      elsif retrieve.response_code == -20
        self.reject!
      end
    end
  end

  def self.retrieve_ca_certs(start, finish, options={})
    Sandbox.find_by_host(options[:db]).use_database unless options[:db].blank?
    cos = Csr.range(start, finish).pending.map(&:certificate_orders).flatten.uniq
    #cannot reference co.retrieve_ca_cert(true) because it filters out issued certificate_contents which contain the external_order_number
    cos.each{ |co|CertificateOrder.unscoped.find_by_ref(co.ref).retrieve_ca_cert(true) }
    SystemAudit.create(owner: nil, target: nil,
                       notes: '',
                       action: "CertificateOrder#retrieve_ca_certs(#{start},#{finish},#{options.to_s})")
  end

  def last_dcv_sent
    return if csr.blank?
    dcvs = csr.domain_control_validations
    (%w(http https).include?(dcvs.last.try(:dcv_method))) ? dcvs.last : dcvs.last_sent
  end


  def self.to_api_string(options={})
    domain = options[:domain_override] || 'https://sws-test.sslpki.com'
    options[:action] = 'create_ssl' if options[:action].blank?
    case options[:action]
      when /create_ssl/
        'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "' +
            {account_key: '',
             secret_key: '',
             product: options[:certificate].api_product_code,
             period: options[:period]}.to_json.gsub('"','\\"') +
            "\" #{domain}/certificates"
      when /create_code_signing/
        'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "' +
            {account_key: '',
             secret_key: '',
             product: options[:certificate].api_product_code,
             period: options[:period]}.to_json.gsub('"','\\"') +
            "\" #{domain}/certificates"
    end
  end

  def exceeds_br_duration?
    certificate_duration(:days).to_i > certificate.max_duration
  end

  def to_api_string(options={action: 'update'})
    domain = options[:domain_override] || 'https://sws-test.sslpki.com'
    api_contacts, api_domains, cc, registrant_params = base_api_params
    if ssl_account.api_credential
      account_key = (options[:show_credentials] || options[:current_user].try('is_system_admins?'.to_sym)) ? ssl_account.api_credential.account_key : '[REDACTED]'
      secret_key = (options[:show_credentials] || options[:current_user].try('is_system_admins?'.to_sym)) ? ssl_account.api_credential.secret_key : '[REDACTED]'
    end
    case options[:action]
      when /update_dcv/
        # registrant_params.merge!(api_domains).merge!(api_contacts)
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    domains: api_domains}
        options[:caller].blank? ?
            'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X PUT -d "' +
                api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /validate/
        # registrant_params.merge!(api_domains).merge!(api_contacts)
        api_params = {account_key: account_key,
                    secret_key: secret_key}
        options[:caller].blank? ?
            'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "' +
                api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificate/#{self.ref}/retry_domain_validation" : api_params
      when /update/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    server_software: cc.server_software_id.to_s,
                    domains: api_domains,
                    contacts: api_contacts,
                    csr: certificate_content.csr.body}.merge!(registrant_params)
        # registrant_params.merge!(api_domains).merge!(api_contacts)
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X PUT -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /revoke/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    reason: 'development test',
                    serials:signed_certificates.map(&:serial),
                    ref: self.ref}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X DELETE -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /create_w_csr/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    product: certificate.api_product_code,
                    period: certificate_duration(:comodo_api).to_s,
                    server_software: cc.server_software_id.to_s,
                    domains: api_domains,
                    contacts: api_contacts,
                    csr: certificate_content.csr.body}.merge!(registrant_params)
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificates" : api_params
      when /create/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    product: certificate.api_product_code,
                    period: certificate_duration(:comodo_api).to_s,
                    domains: api_domains}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificates" : api_params
      when /show/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    query_type: ('all_certificates' unless signed_certificate.blank?), show_subscriber_agreement: 'Y',
                    response_type: ('individually' unless signed_certificate.blank?)}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificate/#{self.ref}" : api_params
      when /index/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    per_page: '10', page: '1'}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificates" : api_params
      when /dcv_emails/
        api_params = {account_key: account_key,
                    secret_key: secret_key}.
            merge!(certificate.is_ucc? ? {domains: certificate_content.domains} : {domain: csr.common_name})
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificates/validations/email" : api_params
      when /dcv_methods_wo_csr/
        api_params = {account_key: account_key,
                    secret_key: secret_key}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X GET -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificate/#{ref}/validations/methods" : api_params
      when /dcv_methods_w_csr/
        api_params = {account_key: account_key,
                    secret_key: secret_key,
                    csr: certificate_content.csr.body}
        options[:caller].blank? ? 'curl -k -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "' +
            api_params.to_json.gsub('"','\\"') + "\" #{domain}/certificates/validations/csr_hash" : api_params
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
      cc.certificate_names.includes(:domain_control_validations).find_by_domains(cc.domains.flatten + [common_name]).each { |cn|
        if cn
          api_domains.merge!(cn.name.to_sym => {dcv:
            cn.domain_control_validations.last_method.try(:method_for_api) ||
                ApiCertificateCreate_v1_4::DEFAULT_DCV_METHOD })
        end
      }
    elsif cc.csr and certificate.is_server?
      api_domains.merge!(cc.csr.common_name.to_sym => {dcv: "#{last_dcv_sent ? last_dcv_sent.method_for_api : 'http_csr_hash'}"})
    end
    api_contacts = {}
    CertificateContent::CONTACT_ROLES.each do |role|
      contact = cc.certificate_contacts.find do |certificate_contact|
        if certificate_contact.roles.include?(role)
          api_contact = {}
          (CertificateContent::RESELLER_FIELDS_TO_COPY + ['country']).each do |field|
            api_contact.merge! field.to_sym => "#{certificate_contact.send(field.to_sym)}"
          end
          api_contacts.merge! role.to_sym => api_contact
        end
      end
    end
    return api_contacts, api_domains, cc, registrant_params
  end
  memoize :base_api_params

  def add_renewal(ren)
    unless ren.blank?
      self.renewal_id = CertificateOrder.find_by_ref(ren).id
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
  def do_auto_renew(notify='success')
    #does a credit already exists for this cert order
    if (renewal.blank? || renewal_attempts_old?) && (auto_renew.blank? || auto_renew == 'scheduled')
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
    certificate_content.try('new?') && workflow_state == 'paid'
  end

  def is_unused?
    certificate_content.try('new?') && (workflow_state == 'paid' || workflow_state == 'refunded')
  end

  def is_prepaid?
    preferred_payment_order == 'prepaid'
  end

  def skip_payment?
    !!(is_prepaid? || (certificate_content && certificate_content.preferred_reprocessing?))
  end

  def is_intranet?
    certificate_content.csr.is_intranet? if certificate_content.try(:csr)
  end

  def server_software
    certificate_content.server_software || ServerSoftware.find(1)
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
      ''
    end
  end

  def status
    if certificate_content.new?
      if certificate.is_code_signing?
        'waiting on registrant or organization information'
      else
        'unused. waiting on certificate signing request (csr)'
      end
    elsif certificate_content.expired?
      'n/a'
    else
      case certificate_content.workflow_state
        when 'csr_submitted'
          'waiting on registrant information from customer'
        when 'info_provided'
          'waiting on contacts information from customer'
        when 'reprocess_requested'
          'reissue requested. waiting on certificate signing request (csr)from customer'
        when 'contacts_provided'
          'waiting on validation from customer'
        when 'pending_validation', 'validated'
          last_sent = csr.try(:last_dcv)
          if last_sent.blank? or (certificate.is_evcs? and validation_histories.count > 0)
            'validating, please wait' #assume intranet
          elsif %w(http https cname http_csr_hash https_csr_hash cname_csr_hash).include?(last_sent.try(:dcv_method))
            'validating, please wait'
          else
            'waiting validation email response from customer'
          end
        when 'issued'
          if certificate_content.expiring?
            if renewal && renewal.paid?
              "renewed. see #{renewal.ref} for renewal"
            else
              'expiring. renew soon'
            end
          else
            'issued'
          end
        when 'canceled'
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
          if signed_certificate.try('is_ev?'.to_sym)
            k == "sslcom_ev_ca_bundle#{ascending_root(override)}.txt"
          elsif signed_certificate.try('is_dv?'.to_sym)
            k == "sslcom_addtrust_ca_bundle#{ascending_root(override)}.txt"
          elsif signed_certificate.try('is_ov?'.to_sym)
            k == "sslcom_high_assurance_ca_bundle#{ascending_root(override)}.txt"
          elsif certificate.is_ev?
            k == "sslcom_ev_ca_bundle#{ascending_root(override)}.txt"
          elsif certificate.is_essential_ssl?
            k == "sslcom_addtrust_ca_bundle#{ascending_root(override)}.txt"
          else
            k == "sslcom_high_assurance_ca_bundle#{ascending_root(override)}.txt"
          end
        end.map{ |k,v|k }
      else
        if signed_certificate.try('is_ev?'.to_sym)
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_ev#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        elsif signed_certificate.try('is_dv?'.to_sym)
          Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:contents]["sslcom_dv#{'_amazon' if is_amazon_balancer? || ["amazon","iis"].include?(override[:server])}.txt"]
        elsif signed_certificate.try('is_ov?'.to_sym)
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
          if certificate.serial =~ /256sslcom/
            if signed_certificate.try('is_ev?'.to_sym)
              k == "sslcom_ev_ca_bundle#{ascending_root(override)}.txt"
              #elsif certificate.is_free?
              #  k=="sslcom_free_ca_bundle.txt"
            elsif signed_certificate.try('is_dv?'.to_sym)
              k == "sslcom_addtrust_ca_bundle#{ascending_root(override)}.txt"
            elsif signed_certificate.try('is_ov?'.to_sym)
              k == "sslcom_high_assurance_ca_bundle#{ascending_root(override)}.txt"
            elsif certificate.is_ev?
              k == "sslcom_ev_ca_bundle#{ascending_root(override)}.txt"
              #elsif certificate.is_free?
              #  k=="sslcom_free_ca_bundle.txt"
            elsif certificate.is_essential_ssl?
              k == "sslcom_addtrust_ca_bundle#{ascending_root(override)}.txt"
            else
              k == "sslcom_high_assurance_ca_bundle#{ascending_root(override)}.txt"
            end
          elsif certificate.comodo_product_id == 342
            k == "free_ssl_ca_bundle#{ascending_root(override)}.txt"
          elsif certificate.comodo_product_id == 43
            k == "trial_ssl_ca_bundle#{ascending_root(override)}.txt"
          else
            k == "ssl_ca_bundle#{ascending_root(override)}.txt"
          end
        end.map{ |k,v|k }
      else
        Certificate::COMODO_BUNDLES.select do |k,v|
          if certificate.serial =~ /256sslcom/
            if signed_certificate.try('is_ev?'.to_sym)
              %w(SSLcomPremiumEVCA.crt COMODOAddTrustServerCA.crt AddTrustExternalCARoot.crt).include? k
            elsif signed_certificate.try('is_dv?'.to_sym)
              %w(SSLcomAddTrustSSLCA.crt AddTrustExternalCARoot.crt).include? k
            elsif signed_certificate.try('is_ov?'.to_sym)
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
          elsif certificate.comodo_product_id == 337 #also maybe 410 (evucc) we'll get there when we place that order
            %w(COMODOExtendedValidationSecureServerCA.crt COMODOAddTrustServerCA.crt AddTrustExternalCARoot.crt).include? k
          elsif certificate.comodo_product_id == 361
            %w(EntrustSecureServerCA.crt USERTrustLegacySecureServerCA.crt).include? k
          else
            %w(SSLcomHighAssuranceCA.crt AddTrustExternalCARoot.crt).include? k
          end
        end.map{ |k,v|k }
      end
    end
  end

  # @param [Hash] override
  def ascending_root(override)
    '_amazon' if is_amazon_balancer? || override[:server] == 'amazon' || override[:ascending_root] == true
  end

  def bundled_cert_dir
    if self.ca == CA_CERTIFICATES[:SSLcomSHA2]
      Settings.intermediate_certs_path + Certificate::BUNDLES[:comodo][:sha2_sslcom_2014][:dir] + '/'
    else
      Settings.intermediate_certs_path
    end
  end

  # @return [String]
  def ca_name
    if common_name =~ /impulshcs/
      I18n.t('labels.ssl_ca')
    else
      'comodo'
    end
  end

  def description_with_tier(target_order=nil)
    extract = ->{
      return description if certificate.reseller_tier.blank?
      tier_label = if target_order && target_order.reseller_tier
                     target_order.reseller_tier.label
                   else
                     certificate.reseller_tier.label
                   end
      description + " (Tier #{tier_label} Reseller)"
    }
    if new_record?
      extract.call
    else
      Rails.cache.fetch("#{cache_key}/description_with_tier/#{target_order.try(:cache_key)}") do
        extract.call
      end
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
        et_tmp = (et == 'processed' ? 'processed_certificate' : et)
        addys << ssl_account.send("preferred_#{et_tmp}_recipients") unless
          ssl_account.send("preferred_#{et_tmp}_recipients") == '0'
        addys << administrative_contact.email if
          administrative_contact &&
            ssl_account.send("preferred_#{et}_include_cert_admin?")
        ct = (et == 'processed' ? 'tech' : 'bill')
        addys << billing_contact.email if
          billing_contact && !et == 'processed' &&
          ssl_account.send("preferred_#{et}_include_cert_#{ct}?")
        addys << technical_contact.email if
          technical_contact && et == 'processed' &&
          ssl_account.send("preferred_#{et}_include_cert_#{ct}?")
      end.uniq
    end
  end

  def certificate_chain_names
    parse_certificate_chain.transpose[0]
  end

  def certificate_chain_types
    parse_certificate_chain.transpose[1]
  end

  def parse_certificate_chain
    preferred_certificate_chain.split(',').
      map(&:strip).map{ |a|a.split(':') }
  end

  def friendly_common_name
    signed_certificate.nonidn_friendly_common_name
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
      cc = (options[:certificate_content] || certificate_content)
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
            'countryName' => csr.country,
            'uniqueValue' => csr.unique_value
          )
          last_sent = csr.domain_control_validations.last_method
          build_comodo_dcv(last_sent, params, options)
        else
          params.merge!(
            'test' => (is_test || !(Rails.env =~ /production/i)) ? 'Y' : 'N',
            'product' => options[:product] || mapped_certificate.comodo_product_id.to_s,
            'serverSoftware' => cc.comodo_server_software_id.blank? ? ServerSoftware::OTHER :
              cc.comodo_server_software_id.to_s,
            'csr' => csr.to_api,
            'prioritiseCSRValues' => 'N',
            'isCustomerValidated' => 'N',
            'responseFormat' => 1,
            'showCertificateID' => 'N',
            'foreignOrderNumber' => ref,
            'uniqueValue' => csr.unique_value,
            'orderNumber' => external_order_number
          )
          last_sent = csr.last_dcv
          #43 is the old comodo 30 day trial
          #look at certificate_duration for more guidance, i don't think the following is ucc safe
          days = certificate_duration(:comodo_api)
          # temporary for a certain customer wanting to move over a number of domains to ssl.com
          if [Certificate::COMODO_PRODUCT_MAPPINGS['free'], 43].include?(
              mapped_certificate.comodo_product_id) #trial cert does not specify duration
            params.merge!('days' => (days).to_s)
          else
            params.merge!('days' => (days + csr.days_left).to_s)
          end
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
        #ssl.com Sub CA certs
        set_comodo_subca(params,options)
        if certificate.is_ev?
          params.merge!('joiCountryName' => (cc.csr.csr_override || cc.registrant).country)
          params.merge!('joiLocalityName' => (cc.csr.csr_override || cc.registrant).city)
          params.merge!('joiStateOrProvinceName' => (cc.csr.csr_override || cc.registrant).state)
        end
        if certificate.is_ucc?
          params.merge!(
            'primaryDomainName' => csr.common_name.downcase,
            'maxSubjectCNs' => 1
          )
        end
      end
    end
  end

  def override_params(options)
    options['countryName'] = 'US'
    options['prioritiseCSRValues'] = 'N'
    # options["product"]=301 #essentialssl
    # options.merge!('caCertificateID' => 401) #essentialssl
  end

  def build_comodo_dcv(last_sent=(csr.domain_control_validations.last_method || csr.last_dcv), params={}, options={})
    if certificate.is_ucc?
      dcv_methods_for_comodo = []
      domains_for_comodo = (options[:certificate_content] || self.certificate_content).all_domains
      certificate_contents.first.certificate_names.
          includes(:domain_control_validations).where{ name >> domains_for_comodo }.each do |cn|
        last = cn.try(:last_dcv_for_comodo)
        dcv_methods_for_comodo << (last.blank? ? ApiCertificateCreate_v1_4::DEFAULT_DCV_METHOD_COMODO : last)
      end
      params.merge!('domainNames' => domains_for_comodo.join(','))
      params.merge!('dcvEmailAddresses' => dcv_methods_for_comodo.join(',')) if (dcv_methods_for_comodo && dcv_methods_for_comodo.count == domains_for_comodo.count)
    else
      if last_sent.blank? || last_sent.dcv_method == 'http'
        params.merge!('dcvMethod' => 'HTTP_CSR_HASH')
      elsif last_sent.dcv_method == 'https'
        params.merge!('dcvMethod' => 'HTTPS_CSR_HASH')
      elsif last_sent.try('is_eligible_to_send?')
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
    csrs.compact.map(&:sent_success).flatten.uniq.each{ |a|a.delete }
    cc = certificate_content
    cc.preferred_reprocessing = false
    cc.save validation: false
  end

  def change_ext_ca_order(new_number)
    ss = csrs.compact.map(&:sent_success).flatten.last
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
      next if i == cc_count - 1 # ignore the most recent certificate_content
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
    self.find_each{ |co|co.orphaned_certificate_contents remove: true }
  end

  # Removes the last certificate_content in the event it was a mistake
  def remove_last_certificate_content
    self.certificate_content.destroy if self.certificate_contents.count > 1
  end

  def external_order_number_meta(options={})
    if notes =~ /(DV|EV|OV)\#\d+/
      if options[:external_order_number] && m = notes.match(/(DV|EV|OV)\##{options[:external_order_number]}/)
        return m[1] unless m.blank?
      elsif options[:validation_type] && m = notes.match(/#{options[:validation_type]}\#(\d+)/)
        return m[1] unless m.blank?
      else
        external_order_number && m = notes.match(/(DV|EV|OV)\##{external_order_number}/)
        return m[1] unless m.blank?
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
    sent_success_map = csrs.map(&:sent_success)
    sent_success_map.flatten.compact.uniq.first.certificate_id if
        csrs && !sent_success_map.blank? &&
        sent_success_map.flatten.compact.uniq.first
    # csrs.sent_success.order_number if csrs && csrs.sent_success
  end

  def transfer_certificate_content(certificate_content)
    self.site_seal.conditionally_activate! unless self.site_seal.conditionally_activated?
    cc = self.certificate_content
    cc.domains = certificate_content.domains
    if certificate_content.preferred_reprocessing?
      self.certificate_contents << certificate_content
      certificate_content.create_registrant(cc.registrant.attributes.except(*ID_AND_TIMESTAMP)) if cc.registrant
      cc.certificate_contacts.each do |contact|
        certificate_content.certificate_contacts << CertificateContact.new(contact.attributes.except(*ID_AND_TIMESTAMP))
      end
      cc = self.certificate_content
    else
      cc.signing_request = certificate_content.signing_request
      cc.server_software = certificate_content.server_software
      cc.agreement = certificate_content.agreement #backwards compatibility with older certificate_content objects
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

  def change_ssl_account!(acct_number)
    sa = SslAccount.find_by_acct_number acct_number
    sa.orders << self.order
    sa.certificate_orders << self
  end

  def valid_recipients_list
    return receipt_recipients unless receipt_recipients.is_a? Array
    receipt_recipients.map(&:split).compact.flatten.uniq
  end

  def validating_domains
    cns = certificate_content.certificate_names
    (certificate.is_ucc? ? cns : [cns.last])
  end

  def domains_validated
    mdc_validation = ComodoApi.mdc_status(self)
    ds = mdc_validation.domain_status
    validated = []
    validating_domains.each_with_index do |cn,i|
      if ds and ds[cn.name]
        name = ds[cn.name]
        validated << cn if (name && name['status'] =~ /validated/i)
      end
    end
    return validated
  end

  def renew_billing?
    co = self.parent
    return false if co.nil?
    ucc = co.certificate.is_ucc? && (co.certificate.is_premium_ssl? != 0)
    ucc && co.certificate_content.expiring? && co.renewal && co.renewal.paid?
  end

  def certificate_contents_ref_label_switch
    certificate_contents.each{ |cc|
      unless cc.ref =~ /^co-/
        ref = cc.ref
        cc.ref = cc.label
        cc.label = ref
        cc.save
      end
    }
  end

  private

  def fill_csr_fields(options, obj)
    unless obj.blank?
      f = {'organizationName' => obj.company_name,
          'organizationalUnitName' => obj.department,
          'postOfficeBox' => obj.po_box,
          'streetAddress1' => obj.address1,
          'streetAddress2' => obj.address2,
          'streetAddress3' => obj.address3,
          'localityName' => obj.city,
          'stateOrProvinceName' => obj.state,
          'postalCode' => obj.postal_code,
          'countryName' => obj.country}
      options.merge!(f.each{ |k,v|f[k] = CGI.escape(v) unless v.blank? })
    end
  end

  def post_process_csr
    certificate_content.submit_csr!
    if ssl_account.is_registered_reseller?
      OrderNotifier.reseller_certificate_order_paid(ssl_account, self).deliver
    else
      valid_recipients_list.each do |c|
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
    bp = order.billing_profile
    response = [bp, (ssl_account.cached_orders.map(&:billing_profile) - [bp]).shift].compact.each do |bp|
      p "purchase using billing_profile_id==#{bp.id}"
      options = {profile: bp, cvv: false}
      new_cert = self.dup
      new_cert.certificate_contents.build
      new_cert.duration = 1 #only renew 1 year at a time
      co = Order.setup_certificate_order(certificate: renewal_certificate, certificate_order: new_cert)
      co.parent = self
      reorder = ssl_account.purchase co
      reorder.cents = co.attributes_before_type_cast['amount'].to_f
      gateway_response = reorder.rebill(options)
      RenewalAttempt.create(
          certificate_order_id: self.id, order_transaction_id: gateway_response.id)
      if gateway_response.success?
        #self.quantity=1
        #clone_for_renew([self], reorder)
        #reorder.line_items.last.sellable.update_attribute :renewal_id, self.id
        co.save
        reorder.save
        if notify == 'success'
          begin
            logger.info "Sending notification to #{valid_recipients_list.join(",")}"
            valid_recipients_list.each do |rec|
              body = OrderNotifier.certificate_order_paid(rec, co, true)
              body.deliver unless body.to.empty?
            end
            RenewalNotification.create(certificate_order_id:
                co.id, subject: body.subject,
                body: body, recipients: valid_recipients_list)
          rescue Exception => e
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

  def clone_for_renew(certificate_orders, order)
    cached_certificate_orders.each do |cert|
      cert.quantity.times do |i|
        #could use cert.dup after >=3.1, but we are currently on 3.0.10 so we'll do this manually
        new_cert = cert.dup
        cert.sub_order_items.each { |soi|
          new_cert.sub_order_items << soi.dup
        }
        if cert.migrated_from_v2?
          pvg = new_cert.sub_order_items[0].
              product_variant_item.product_variant_group
          pvg.variantable = cert.renewal_certificate
          pvg.save
        end
        new_cert.line_item_qty = cert.quantity if(i == cert.quantity - 1)
        new_cert.preferred_payment_order = 'prepaid'
        new_cert.save
        cc = CertificateContent.new
        cc.certificate_order = new_cert
        cc.save
        order.line_items.build sellable: new_cert
      end
    end
  end

  # used for determining which Sub Ca certs to use
  def set_comodo_subca(params, options={})
    cci = Settings.ca_certificate_id_dv # default is DV
    if options[:ca_certificate_id]
      cci = options[:ca_certificate_id]
    elsif [CA_CERTIFICATES[:SSLcomSHA2]].include? self.ca
      cci = if external_order_number_meta == 'EV'
              Settings.ca_certificate_id_ev
            elsif external_order_number_meta == 'OV'
              Settings.ca_certificate_id_ov
            elsif external_order_number_meta == 'DV'
              Settings.ca_certificate_id_dv
            else
              if Settings.send_dv_first
                Settings.ca_certificate_id_dv #first time needs to be DV
              else
                if certificate.is_ev?
                  Settings.ca_certificate_id_ev
                elsif certificate.is_ov?
                  Settings.ca_certificate_id_ov
                else
                  Settings.ca_certificate_id_dv
                end
              end
            end
    elsif certificate.serial =~ /256sslcom/
      cci = if certificate.is_ev?
                    '403'
                  elsif certificate.is_essential_ssl?
                    '401'
                  else
                    '402'
                  end
    end
    params.merge!('caCertificateID' => cci.to_s)
  end


  def self.trial_conversions(start=30.days.ago, finish=Date.today)
    free, nonfree, result, stats, count = {}, {}, {}, [], 0
    CertificateOrder.range(start, finish).not_test.free.map{ |co|free.merge!(co.id.to_s => co.all_domains) unless co.all_domains.blank? }
    CertificateOrder.range(start, finish).not_test.nonfree.map{ |co|nonfree.merge!(co.id.to_s => co.all_domains) unless co.all_domains.blank? }
    nonfree.each do |nk,nv|
      free.each do |fk,fv|
        if !(nv & fv).empty?
          count += 1
          co_fk = CertificateOrder.find(fk)
          co_nk = CertificateOrder.find(nk)
          result.merge!([co_fk.ref, 0.01 * co_fk.amount, co_fk.created_at.strftime('%b %d, %Y')] =>
                            [co_nk.ref, 0.01 * co_nk.amount, co_nk.created_at.strftime('%b %d, %Y')])
          stats << [co_fk.ref, 0.01 * co_fk.amount, co_fk.created_at.strftime('%b %d, %Y'),
              co_nk.ref, 0.01 * co_nk.amount, co_nk.created_at.strftime('%b %d, %Y')].join('/')
          free.delete fk
          break
        end
      end
    end
    File.open('/tmp/trial_conversions.txt', 'w') { |file| file.write stats.join("\n") }
    [count,result]
  end

  # cron job that flags unused certificate_order credits as expired after a period of time (1 year)
  def self.expire_credits(options={})
    Website.sandbox_db.use_database if options[:db] == 'sandbox'
    CertificateOrder.unflagged_expired_credits.update_all(is_expired: true)
    SystemAudit.create(owner: nil, target: nil,
                       notes: '',
                       action: "CertificateOrder#expire_credits(#{options.to_s})")
  end

  def self.to_csv
    columns = ['Order Ref', 'Order Label', 'Duration', 'Signed Certificate', 'Status', 'Effective Date', 'Expiration Date']

    CSV.generate(headers: true) do |csv|
      csv << columns

      all.find_each do |cert_order|
        signed_certs = cert_order.signed_certificates

         csv << columns.map do |attr|
           if attr == 'Order Ref'
             cert_order.ref
           elsif attr == 'Order Label'
             cert_order.certificate.title
           elsif attr == 'Duration'
             cert_order.certificate_content.duration
           elsif (attr == 'Signed Certificate') && signed_certs.present?
             signed_certs.map(&:common_name)
           elsif (attr == 'Status') && signed_certs.present?
             signed_certs.map(&:status)
           elsif (attr == 'Effective Date') && signed_certs.present?
             signed_certs.map(&:effective_date)
           elsif (attr == 'Expiration Date') && signed_certs.present?
             signed_certs.map(&:expiration_date)
           end
         end
      end
    end
  end
end
