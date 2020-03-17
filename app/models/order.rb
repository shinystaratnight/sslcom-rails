# == Schema Information
#
# Table name: orders
#
#  id                     :integer          not null, primary key
#  approval               :string(255)
#  billable_type          :string(255)
#  canceled_at            :datetime
#  cents                  :integer
#  cur_non_wildcard       :integer
#  cur_wildcard           :integer
#  currency               :string(255)
#  description            :string(255)
#  ext_affiliate_credited :boolean
#  ext_affiliate_name     :string(255)
#  ext_customer_ref       :string(255)
#  invoice_description    :text(65535)
#  lock_version           :integer          default(0)
#  max_non_wildcard       :integer
#  max_wildcard           :integer
#  non_wildcard_cents     :integer
#  notes                  :string(255)
#  paid_at                :datetime
#  po_number              :string(255)
#  quote_number           :string(255)
#  reference_number       :string(255)
#  state                  :string(255)      default("pending")
#  status                 :string(255)      default("active")
#  type                   :string(255)
#  wildcard_cents         :integer
#  created_at             :datetime
#  updated_at             :datetime
#  address_id             :integer
#  billable_id            :integer
#  billing_profile_id     :integer
#  deducted_from_id       :integer
#  ext_affiliate_id       :string(255)
#  invoice_id             :integer
#  reseller_tier_id       :integer
#  visitor_token_id       :integer
#
# Indexes
#
#  index_orders_on_address_id                               (address_id)
#  index_orders_on_billable_id                              (billable_id)
#  index_orders_on_billable_id_and_billable_type            (billable_id,billable_type)
#  index_orders_on_billable_type                            (billable_type)
#  index_orders_on_billing_profile_id                       (billing_profile_id)
#  index_orders_on_created_at                               (created_at)
#  index_orders_on_deducted_from_id                         (deducted_from_id)
#  index_orders_on_id_and_state                             (id,state)
#  index_orders_on_id_and_type                              (id,type)
#  index_orders_on_invoice_id                               (invoice_id)
#  index_orders_on_po_number                                (po_number)
#  index_orders_on_quote_number                             (quote_number)
#  index_orders_on_reference_number                         (reference_number)
#  index_orders_on_reseller_tier_id                         (reseller_tier_id)
#  index_orders_on_state_and_billable_id_and_billable_type  (state,billable_id,billable_type)
#  index_orders_on_state_and_description_and_notes          (state,description,notes)
#  index_orders_on_status                                   (status)
#  index_orders_on_updated_at                               (updated_at)
#  index_orders_on_visitor_token_id                         (visitor_token_id)
#

require 'monitor'
require 'bigdecimal'

class Order < ApplicationRecord
  extend Memoist
  include V2MigrationProgressAddon
  include SmimeClientEnrollable
  include Pagable
  include WorkflowActiverecord

  belongs_to  :billable, :polymorphic => true, touch: true
  belongs_to  :address
  belongs_to  :billing_profile, -> { unscope(where: [:status]) }
  belongs_to  :billing_profile_unscoped, foreign_key: :billing_profile_id, class_name: "BillingProfileUnscoped"
  belongs_to  :deducted_from, class_name: "Order", foreign_key: "deducted_from_id"
  belongs_to  :visitor_token
  belongs_to  :invoice, class_name: "Invoice", foreign_key: :invoice_id
  belongs_to  :reseller_tier, foreign_key: :reseller_tier_id
  has_many    :line_items, dependent: :destroy, after_add: Proc.new { |p, d| p.amount += d.amount}
  has_many    :certificate_orders, through: :line_items, :source => :sellable, :source_type => 'CertificateOrder', unscoped: true
  has_many    :payments
  has_many    :transactions, class_name: 'OrderTransaction', dependent: :destroy
  has_many    :refunds, dependent: :destroy
  has_many    :order_transactions
  has_many    :taggings, as: :taggable
  has_many    :tags, through: :taggings
  has_and_belongs_to_many    :discounts

  money :amount, cents: :cents
  money :wildcard_amount, cents: :wildcard_cents
  money :non_wildcard_amount, cents: :non_wildcard_cents

  before_create :total, :determine_description
  after_create :generate_reference_number, :commit_discounts, :domains_adjustment_notice

  # is_free? is used to as a way to allow orders that are not charged (ie cent==0)
  attr_accessor :is_free, :receipt, :deposit_mode, :temp_discounts

  after_initialize do
    if new_record?
      self.amount = 0 if self.amount.blank?
      self.is_free ||= false
      self.receipt ||= false
      self.deposit_mode ||= false
    end
    self.cur_wildcard = nil if self.cur_wildcard.blank?
    self.cur_non_wildcard = nil if self.cur_non_wildcard.blank?
    self.max_wildcard = nil if self.max_wildcard.blank?
    self.max_non_wildcard = nil if self.max_non_wildcard.blank?
    self.reseller_tier_id = nil if self.reseller_tier_id.blank?
    self.wildcard_cents = 0 if self.wildcard_cents.blank?
    self.non_wildcard_cents = 0 if self.non_wildcard_cents.blank?
  end

  FAW                    = "Funded Account Withdrawal"
  DOMAINS_ADJUSTMENT     = "Domains Adjustment"
  SSL_CERTIFICATE        = "SSL.com Certificate Order"
  MI_PAYMENT             = "Monthly Invoice Payment"
  DI_PAYMENT             = "Daily Invoice Payment"
  S_OR_C_ENROLLMENT      = "S/MIME or Client Enrollment"
  CERTIFICATE_ENROLLMENT = "Certificate Enrollment"

  # If team's billing_method is set to 'monthly', grab all orders w/'approved' approval
  # when running charges at the end of the month for orders from ucc reprocessing.
  BILLING_STATUS = %w{approved pending declined}
  #go live with this
#  default_scope{ includes(:line_items).where({line_items:}
#    [:sellable_type !~ ResellerTier.to_s]}  & (:billable_id - [13, 5146])).order('created_at desc')
  #need to delete some test accounts
  default_scope ->{includes(:line_items).where{state << ['payment_declined','fully_refunded','charged_back', 'canceled']}.
                    order("orders.created_at desc").uniq}

  scope :not_new, lambda {
    joins{line_items.sellable(CertificateOrder).outer}.
        where{line_items.sellable(CertificateOrder).workflow_state=='paid'}.
    joins{line_items.sellable(Deposit).outer}
  }

  scope :not_test, lambda {
    joins{line_items.sellable(CertificateOrder).outer}.
        where{(line_items.sellable(CertificateOrder).is_test==nil) |
        (line_items.sellable(CertificateOrder).is_test==false)}
  }

  scope :is_test, -> {
    joins{line_items.sellable(CertificateOrder)}.
        where{(line_items.sellable(CertificateOrder).is_test==true)}
  }

  scope :search, lambda {|term|
    term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
    filters = { amount: nil, email: nil, login: nil, account_number: nil, product: nil, created_at: nil,
                discount_amount: nil, company_name: nil, ssl_slug: nil, is_test: nil, reference_number: nil,
                monthly_invoice: nil, order_tags: nil
              }
    filters.each{|fn, fv|
      term.delete_if {|s|s =~ Regexp.new(fn.to_s+"\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1}
    }
    term = term.empty? ? nil : term.join(" ")
    return nil if [term,*(filters.values)].compact.empty?
    ref = (term=~/\b(co-[^\s]+)/ ? $1 : nil)
    result = joins{}
    result = result.joins{line_items.sellable(CertificateOrder)} if ref
    unless term.blank?
      result = result.joins{discounts.outer}.joins{billing_profile_unscoped.outer}.where{
        (billing_profile_unscoped.last_digits == "#{term}") |
        (billing_profile_unscoped.first_name =~ "%#{term}%") |
        (billing_profile_unscoped.last_name =~ "%#{term}%") |
        (billing_profile_unscoped.address_1 =~ "%#{term}%") |
        (billing_profile_unscoped.address_2 =~ "%#{term}%") |
        (billing_profile_unscoped.city =~ "%#{term}%") |
        (billing_profile_unscoped.state =~ "%#{term}%") |
        (billing_profile_unscoped.phone =~ "%#{term}%") |
        (billing_profile_unscoped.country =~ "%#{term}%") |
        (billing_profile_unscoped.company =~ "%#{term}%") |
        (billing_profile_unscoped.notes =~ "%#{term}%") |
        (billing_profile_unscoped.postal_code =~ "%#{term}%") |
        (discounts.ref =~ "%#{term}%") |
        (discounts.label =~ "%#{term}%") |
        (reference_number =~ "%#{term}%") |
        (notes =~ "%#{term}%") |
        (ref ? (line_items.sellable(CertificateOrder).ref=~ "%#{ref}%") :
            (notes =~ "%#{term}%")) # searching notes twice is a hack, nil did not work
        }
    end
    %w(is_test).each do |field|
      query=filters[field.to_sym]
      if query.try("true?")
        result = result.send(field)
      else
        result = result.not_test
      end
    end
    %w(reference_number).each do |field|
      query=filters[field.to_sym]
      result = result.where(field.to_sym => query.split(',')) if query
    end
    %w(login email).each do |field|
      query=filters[field.to_sym]
      result = result.joins{billable(SslAccount).users}.where{
        (billable(SslAccount).users.send(field.to_sym) =~ "%#{query}%")} if query
    end
    %w(account_number company_name ssl_slug).each do |field|
      query=filters[field.to_sym]
      result = result.joins{billable(SslAccount).outer}.where{
        (billable(SslAccount).send((field=="account_number" ? "acct_number" : field).to_sym) =~ "%#{query}%")} if query
    end
    %w(product).each do |field|
      query=filters[field.to_sym]
      case query
      when /domain_adjustments/
          result = result.where(description: Order::DOMAINS_ADJUSTMENT)
        when /deposit/
          result = result.joins{line_items.sellable(Deposit)}
            .where.not(description: Order::FAW)
        when /faw/
          result = result.joins{line_items.sellable(Deposit)}
            .where(description: Order::FAW)
        when /certificate/
          result = result.joins{line_items.sellable(CertificateOrder)}
        when /reseller/
          result = result.joins{line_items.sellable(ResellerTier)}
        when /ucc/,/evucc/,/basicssl/,/wildcard/,/ev/,/premiumssl/,/ev-code-signing/,/code-signing/
          result = result.joins{line_items.sellable(CertificateOrder).sub_order_items.product_variant_item.product_variant_group.
              variantable(Certificate)}.where{certificates.product=="#{query}"}
      end
    end
    %w(amount).each do |field|
      if filters[field.to_sym]
        query=filters[field.to_sym].split("-")
        if query.count==1
          query=filters[field.to_sym]
          case query
            when /\A>/,/\A</
              result = result.where{(cents > ("#{query[1..-1]}".to_f*100).to_i)}
            else
              result = result.where{(cents == ("#{query}".to_f*100).to_i)}
          end
        else
          result = result.where{cents >> ((query[0].to_f*100).to_i..(query[1].to_f*100).to_i)}
        end
      end
    end
    %w(order_tags).each do |field|
      query = filters[field.to_sym]
      result = result.joins(:tags).where(tags: {name: query.split(',')}) if query
    end
    %w(created_at).each do |field|
      query=filters[field.to_sym]
      if query
        query=query.split("-")
        start = Date.strptime query[0], "%m/%d/%Y"
        finish = query[1] ? Date.strptime(query[1], "%m/%d/%Y") : start+1.day
        result = result.where{created_at >> (start..finish)}
      end
    end
    result = result.where.not(invoice_id: nil) unless filters[:monthly_invoice].nil?
    result.uniq.order("orders.created_at desc")
  } do

    def amount
      sum(:cents)*0.01
    end
  end

  scope :not_free, lambda{
    not_new.where :cents.gt=>0
  }

  scope :tracked_visitor, ->{where{visitor_token_id != nil}}

  scope :range, lambda{|start, finish|
    if start.is_a? String
      s= start =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
      f= finish =~ /\// ? "%m/%d/%Y" : "%m-%d-%Y"
      start = Date.strptime start, s
      finish = Date.strptime finish, f
    end
    where{created_at >> (start..finish)}.uniq

  } do

    def amount
      sum(:cents)*0.01
    end
  end

  SmimeClientEnrollValidate = Struct.new(:user_id, :order_id) do
    def perform
      user = User.find user_id
      order = Order.find order_id
      if user && order
        order.smime_client_enroll_recipients(user_id)
      end
    end
  end

  def smime_client_enrollment_validate(user_id)
    Delayed::Job.enqueue SmimeClientEnrollValidate.new(user_id, id)
  end

  def self.range_amount(start, finish)
    amount = BigDecimal(range(start, finish).amount.to_s)
    rounded = (amount * 100).round / 100
    '%.02f' % rounded
  end

  def discount_amount(items=nil)
    cur_amount = items ? line_items.map(&:cents).sum : amount.cents
    t=0
    unless id
      temp_discounts.each do |d|
        d=Discount.find(d)
        d.apply_as=="percentage" ? t+=(d.value.to_f*cur_amount) : t+=(d.value.to_i)
      end unless temp_discounts.blank?
    else
      self.discounts.each do |d|
        d.apply_as=="percentage" ? t+=(d.value.to_f*cur_amount) : t+=(d.value.to_i)
      end unless self.discounts.empty?
    end
    Money.new(t)
  end

  def lead_up_to_sale
    u = billable.primary_user
    history = u.browsing_history("01/01/2000", created_at, "desc")
    history = history.compact.sort{|x,y|x[1][0]<=>y[1][0]}.last if history.count > 1
    history.shift
    (["Order for amount #{amount} was made on #{created_at}"]<<history).flatten
  end

  def finalize_sale(options)
    params = options[:params]
    self.deducted_from = options[:deducted_from]
    self.apply_discounts(params) #this needs to happen before the transaction but after the final incarnation of the order
    self.update_attribute :visitor_token, options[:visitor_token] if options[:visitor_token]
    self.mark_paid!
    self.credit_affiliate(options[:cookies])
    self.commit_discounts
  end

  def apply_discounts(params)
    if (params[:discount_code])
      self.temp_discounts = []
      general_discount = Discount.viable.general.find_by_ref(params[:discount_code])
      if general_discount
        self.temp_discounts << general_discount.id
      end
    end
  end

  def credit_affiliate(cookies)
    if !(self.is_test? || self.cents==0)
      if cookies[ShoppingCart::AID] && Affiliate.exists?(cookies[ShoppingCart::AID])
        self.ext_affiliate_name="idevaffiliate"
        self.ext_affiliate_id="72198"
      else
        case Settings.affiliate_program
          when "idevaffiliate"
            self.ext_affiliate_name="idevaffiliate"
            self.ext_affiliate_id="72198"
          when "shareasale"
            self.ext_affiliate_name="shareasale"
            self.ext_affiliate_id="50573"
        end
      end
      self.ext_affiliate_credited=false
      self.save validate: false
    end
  end

  def total
    unless reprocess_ucc_order? ||
      invoice_payment? ||
      on_payable_invoice? ||
      voided_on_payable_invoice? ||
      domains_adjustment? ||
      no_limit_order?

      self.amount = line_items.inject(0.to_money) {|sum,l| sum + l.amount }
    end
  end
  memoize :total

  def final_amount
    Money.new(amount.cents)-discount_amount
  end

  workflow_column :state

  workflow do
    state :invoiced do
      event :payment_authorized, transitions_to: :authorized
      event :invoice_paid!, transitions_to: :paid_by_invoice
      event :full_refund, transitions_to: :fully_refunded do |complete=true|
        if original_order?
          line_items.each {|li|li.sellable.refund! if(
          li.sellable.respond_to?("refund!".to_sym) && !li.sellable.refunded?)} if complete
        end
      end
      event :partial_refund, transitions_to: :partially_refunded do |ref|
        li = line_items.find {|li| li.sellable.try(:ref) == ref}
        if li
          decrement! :cents, li.cents
          if original_order? && li.sellable.respond_to?("refund!".to_sym) && !li.sellable.refunded?
            li.sellable.refund!
          end
        end
      end
      event :reject, transitions_to: :rejected do |complete=true|
        line_items.each {|li| li.sellable_unscoped.reject!} if complete
      end
      event :cancel, transitions_to: :canceled do |complete=true|
        cancel_order
      end
      event :charge_back, transitions_to: :charged_back do |complete=true|
        line_items.each {|li| li.sellable_unscoped.charge_back!} if complete
      end
    end

    state :pending do
      event :payment_invoiced, transitions_to: :invoiced
      event :give_away, transitions_to: :payment_not_required
      event :payment_authorized, transitions_to: :authorized
      event :transaction_declined, :transitions_to => :payment_declined
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|li.sellable_unscoped.reject!} if complete
      end
    end

    state :authorized do
      event :payment_captured, transitions_to: :paid
      event :transaction_declined, transitions_to: :authorized
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|li.sellable_unscoped.reject!} if complete
      end
    end

    state :paid do
      event :full_refund, transitions_to: :fully_refunded do |complete=true|
        line_items.each {|li|li.sellable_unscoped.refund! if(
          li.sellable_unscoped.respond_to?("refund!".to_sym) && !li.sellable_unscoped.refunded?)} if complete
      end
      event :partial_refund, transitions_to: :partially_refunded do |ref|
        li=line_items.find {|li|li.sellable_unscoped.try(:ref)==ref}
        if li
          decrement! :cents, li.cents
          li.sellable_unscoped.refund! if (li.sellable_unscoped.respond_to?("refund!".to_sym) && !li.sellable_unscoped.refunded?)
        end
      end
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|li.sellable_unscoped.reject!} if complete
      end
      event :cancel, transitions_to: :canceled do |complete=true|
        cancel_order
      end
      event :charge_back, transitions_to: :charged_back do |complete=true|
        line_items.each {|li|li.sellable_unscoped.charge_back!} if complete
      end
    end

    state :fully_refunded do
      event :unrefund, transitions_to: :paid do |complete=true|
        line_items.each {|li|
          CertificateOrder.unscoped.find_by_id(li.sellable_id).unrefund! if li.sellable_type=="CertificateOrder"} if complete
      end
      event :charge_back, transitions_to: :charged_back do |complete=true|
        line_items.each {|li|li.sellable_unscoped.charge_back!} if complete
      end
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|
          CertificateOrder.unscoped.find_by_id(li.sellable_id).reject! if li.sellable_type=="CertificateOrder"} if complete
      end
    end

    state :partially_refunded do
      event :partial_refund, transitions_to: :partially_refunded do |ref, amount=nil|
        item =line_items.find {|li|li.sellable_unscoped.try(:ref)==ref} || certificate_orders.find {|co| co.try(:ref)==ref}
        if item
          decrement! :cents, (amount ? amount : item.cents)
          to_refund = item.is_a?(LineItem) ? item.sellable : item
          to_refund.refund! if (to_refund.respond_to?("refund!".to_sym) && !to_refund.refunded?)
        end
      end
      event :full_refund, transitions_to: :fully_refunded do |complete=true|
        line_items.each {|li|li.sellable_unscoped.refund! if(
          li.sellable_unscoped.respond_to?("refund!".to_sym) && !li.sellable_unscoped.refunded?)} if complete
      end
      event :unrefund, transitions_to: :paid do |complete=true|
        line_items.each {|li|
          CertificateOrder.unscoped.find_by_id(li.sellable_id).unrefund! if li.sellable_type=="CertificateOrder"} if complete
      end
      event :charge_back, transitions_to: :charged_back do |complete=true|
        line_items.each {|li|li.sellable_unscoped.charge_back!} if complete
      end
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|
          CertificateOrder.unscoped.find_by_id(li.sellable_id).reject! if li.sellable_type=="CertificateOrder"} if complete
      end
    end

    state :charged_back

    state :rejected do
      event :partial_refund, transitions_to: :partially_refunded do |ref, amount=nil|
        item =line_items.find {|li|li.sellable_unscoped.try(:ref)==ref} || certificate_orders.find {|co| co.try(:ref)==ref}
        if item
          decrement! :cents, (amount ? amount : item.cents)
          to_refund = item.is_a?(LineItem) ? item.sellable : item
          to_refund.refund! if (to_refund.respond_to?("refund!".to_sym) && !to_refund.refunded?)
        end
      end
      event :full_refund, transitions_to: :fully_refunded do |complete=true|
        line_items.each {|li|li.sellable_unscoped.refund! if(
          li.sellable_unscoped.respond_to?("refund!".to_sym) && !li.sellable_unscoped.refunded?)} if complete
      end
      event :unreject, transitions_to: :paid do |complete=true|
        line_items.each {|li|
          CertificateOrder.unscoped.find_by_id(li.sellable_id).unreject! if li.sellable_type=="CertificateOrder"} if complete
      end
      event :cancel, transitions_to: :canceled do |complete=true|
        cancel_order
      end
    end

    state :payment_declined do
      event :give_away, transitions_to: :payment_not_required
      event :payment_authorized, transitions_to: :authorized
      event :transaction_declined, :transitions_to => :payment_declined

    end

    state :payment_not_required do
      event :full_refund, transitions_to: :fully_refunded do |complete=true|
        line_items.each {|li|li.sellable_unscoped.refund! if li.sellable_unscoped.respond_to?("refund!".to_sym)} if complete
      end
      event :cancel, transitions_to: :canceled do |complete=true|
        cancel_order
      end
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|li.sellable_unscoped.reject!} if complete
      end
    end

    state :canceled do
      event :full_refund, transitions_to: :fully_refunded do |complete=true|
        line_items.each {|li|li.sellable_unscoped.refund! if li.sellable_unscoped.respond_to?("refund!".to_sym)} if complete
      end
      event :cancel, transitions_to: :canceled do |complete=true|
        cancel_order
      end
      event :charge_back, transitions_to: :charged_back do |complete=true|
        line_items.each {|li|li.sellable_unscoped.charge_back!} if complete
      end
      event :reject, :transitions_to => :rejected do |complete=true|
        line_items.each {|li|li.sellable_unscoped.reject!} if complete
      end
    end
  end

  ## BEGIN acts_as_state_machine
  #acts_as_state_machine :initial => :pending
  #
  #state :pending
  #state :authorized
  #state :paid
  #state :fully_refunded
  #state :payment_declined
  #state :payment_not_required
  #
  #event :give_away do
  #  transitions :from => :pending,
  #              :to   => :payment_not_required
  #
  #  transitions :from => :payment_declined,
  #              :to   => :payment_not_required
  #end
  #
  #event :payment_authorized do
  #  transitions :from => :pending,
  #              :to   => :authorized
  #
  #  transitions :from => :payment_declined,
  #              :to   => :authorized
  #end
  #
  #event :payment_captured do
  #  transitions :from => :authorized,
  #              :to   => :paid
  #end
  #
  #event :transaction_declined do
  #  transitions :from => :pending,
  #              :to   => :payment_declined
  #
  #  transitions :from => :payment_declined,
  #              :to   => :payment_declined
  #
  #  transitions :from => :authorized,
  #              :to   => :authorized
  #end
  #
  #event :full_refund do
  #  transitions :from => :paid,
  #              :to   => :fully_refunded
  #end
  ## END acts_as_state_machine

  # BEGIN number

  def get_full_refund_amount
    refunded = 0
    if fully_refunded?
      funded_amt   = get_funded_account_amount
      not_standard = on_payable_invoice? || (domains_adjustment? && funded_amt > 0)
      refunded     = (not_standard ? cents : get_total_merchant_amount) + funded_amt
    end

    if partially_refunded?
      refunded_items = CertificateOrder.unscoped
        .where(id: line_items.map(&:sellable_id), workflow_state: 'refunded')
      if refunded_items.any?
        refunded_items.each { |item| refunded += make_available_line(item) }
      else
        refunded = get_total_merchant_refunds
      end
    end
    refunded
  end

  def merchant_fully_refunded?
    get_total_merchant_refunds == get_total_merchant_amount
  end

  def no_limit_order?
    state == 'invoiced'
  end

  def voided_on_payable_invoice?
    !invoice_id.blank? && (
      fully_refunded? ||
      partially_refunded? ||
      canceled? ||
      rejected? ||
      charged_back?
    )
  end

  def on_payable_invoice?
    !invoice_id.blank? && state == 'invoiced'
  end

  def approved_for_invoice?
    on_payable_invoice? && approval == 'approved'
  end

  def removed_from_invoice?
    on_payable_invoice? && approval == 'rejected'
  end

  def invoice_address
    Invoice.find_by(order_id: id)
  end

  def reprocess_ucc_order?
    self.type == 'ReprocessCertificateOrder'
  end

  def domains_adjustment?
    description == DOMAINS_ADJUSTMENT
  end

  def reprocess_ucc_free?
    reprocess_ucc_order? && cents==0
  end

  def monthly_invoice_order?
    # Payment for total of monthly invoice
    description == MI_PAYMENT
  end

  def daily_invoice_order?
    # Payment for total of daily invoice
    description == DI_PAYMENT
  end

  def invoice_payment?
    monthly_invoice_order? || daily_invoice_order?
  end

  def faw_order?
    description == FAW # Funded Account Withdrawal
  end

  def get_order_type_label
    if reprocess_ucc_order?
      '(Reprocess)'
    elsif domains_adjustment? && !reprocess_ucc_order?
      '(Domains Adjustment)'
    else
      ''
    end
  end

  # Get all orders for certificate orders or line items of main order.
  def get_cached_orders
    certificate_orders.map(&:orders).inject([]) do |all, o|
      all << o if o != self
      all.flatten
    end
  end

  # Fetches all domain counts that were added during UCC domains adjustment
  def get_reprocess_domains
    Rails.cache.fetch("#{cache_key}/get_reprocess_domains") do
      co           = certificate_orders.first
      cc           = get_reprocess_cc(co)
      cs           = cc.signed_certificate if cc
      cc_domains   = (cc.nil? || (cc && cc.domains.blank?)) ? [] : cc.domains
      cur_domains  = (cc && cs) ? cs.subject_alternative_names : cc_domains
      non_wildcard = cur_domains.map {|d| d if !d.include?('*')}.compact
      wildcard     = cur_domains.map {|d| d if d.include?('*')}.compact

      tot_non_wildcard = if cur_non_wildcard.blank?
                           non_wildcard.count - co.get_reprocess_max_nonwildcard(cc).count
                         else
                           cur_non_wildcard
                         end

      tot_wildcard = if cur_wildcard.blank?
                       wildcard.count - co.get_reprocess_max_wildcard(cc).count
                     else
                       cur_wildcard
                     end

      tot_non_wildcard  = tot_non_wildcard < 0 ? 0 : tot_non_wildcard
      tot_wildcard      = tot_wildcard < 0 ? 0 : tot_wildcard
      new_domains_count = tot_non_wildcard + tot_wildcard

      {
          all:                cur_domains,
          new_domains_count:  (new_domains_count < 0 ? 0 : new_domains_count),
          cur_wildcard:       wildcard.count,
          wildcard:           tot_wildcard,
          non_wildcard:       tot_non_wildcard
      }
    end
  end

  def get_ccref_from_notes
    unless notes.blank?
      notes.split(').').first.split.last.delete(')')
    end
  end

  def get_reprocess_cc(co)
    cc = nil
    if co
      str = get_ccref_from_notes
      cc  = if str.nil?
        []
      else
        co.certificate_contents.where("ref = ? OR id = ?", str, str)
      end
      cc  = cc.any? ? cc.first : nil
    end
    cc
  end

  def get_reprocess_orders
    result = {}
    cached_certificate_orders.includes(:orders).each do |co|
      current = []
      co.orders.order(created_at: :asc).each do |o|
        if o.reprocess_ucc_order?
          current << {
            date:       o.created_at.strftime('%F'),
            order_ref:  o.reference_number,
            domains:    o.get_reprocess_domains,
            amount:     o.get_full_reprocess_format
          }
        end
      end
      result[co.ref] = current if current.any?
    end
    result
  end

  def number
    SecureRandom.base64(32)
  end

  def invoice_denied_order(ssl_account)
    cur_invoice_id = Invoice.get_or_create_for_team(ssl_account).try(:id)
    if cur_invoice_id
      update(
        state:      'invoiced',
        invoice_id: cur_invoice_id,
        approval:   'approved'
      )
      transactions.destroy_all
    end
  end

  # BEGIN purchase
  def purchase(credit_card, options = {})
    options[:order_id] = number
    transaction do
      current_amount = options[:amount] ? Money.new(options[:amount]) : final_amount
      authorization = OrderTransaction.purchase(current_amount, credit_card, options)
      if authorization && authorization.is_a?(OrderTransaction)
        transactions.push(authorization)

        if authorization.success?
          payment_authorized!
        else
          if !invoice_payment? && %w{insufficient_funds do_not_honor transaction_not_allowed}.include?(authorization.params[:decline_code])
            unless invoiced?
              OrderNotifier.invoice_declined_order(
                order: self,
                user_email: options[:owner_email],
                decline_code: authorization.params[:decline_code]
              ).deliver_now
              payment_invoiced!
            end
          else
            transaction_declined!
            errors[:base] << authorization.message
          end
        end
      end
      authorization
    end
  end
  # END purchase

  # BEGIN authorization_reference
  def authorization_reference
    if authorization = transactions.find_by_action_and_success('authorization',
        true, :order => 'id ASC')
      authorization.reference
    end
  end
  # END authorization_reference

  def generate_reference_number
      update_attribute :reference_number, SecureRandom.hex(2)+
        '-'+Time.now.to_i.to_s(32)
  end

  def commit_discounts
    temp_discounts.each do |td|
      discounts<<Discount.viable.find(td)
    end unless temp_discounts.blank?
    temp_discounts=nil
  end

  def cached_certificate_orders
    CertificateOrder.unscoped.where(id: (Rails.cache.fetch("#{cache_key}/cached_certificate_orders") do
      certificate_orders.pluck(:id)
    end)).order(created_at: :desc)
  end
  memoize :cached_certificate_orders

  def is_free?
    @is_free.try(:==, true) || (cents==0)
  end

  def mark_paid!
    payment_authorized! unless authorized?
    payment_captured!
  end

#  def self.cart_items(session, cookies)
#    session[:cart_items] = []
#    unless SERVER_SIDE_CART
#      cart_items = cart_contents
#      cart_items.each_with_index{|line_item, i|
#        pr=line_item[ShoppingCart::PRODUCT_CODE]
#        if !pr.blank? &&
#          ((line_item.count > 1 && Certificate.find_by_product(pr)) ||
#          ApplicationRecord.find_from_model_and_id(pr))
#          session[:cart_items] << line_item
#        else
#          cart_items.delete line_item
#          delete_cart_items
#          save_cart_items(cart_items)
#        end
#      }
#    end
#  end

  # creates a new order based on this order, but still needs to be assigned to a purchased object
  # the following are valid options:
  # :description, :profile, :cvv, :amount
  def rebill(options)
    options.reverse_merge!({description: Order::SSL_CERTIFICATE,
        profile: self.billing_profile, cvv: true})
    options[:profile].cycled_years.map do |exp_year|
      profile=options[:profile]
      params = {expiration_year: exp_year, cvv: options[:cvv]}
      if (Rails.env=~/development/i && defined?(BillingProfile::TEST_AMOUNT))
        params.merge!(card_number: "4222222222222")
        self.amount= BillingProfile::TEST_AMOUNT
      end
      credit_card = profile.build_credit_card(params)
      next unless ActiveMerchant::Billing::Base.mode == :test ?
          true : credit_card.valid?
      self.description = options[:description]
      gateway_response = self.purchase(credit_card, profile.build_info(options[:description]))
      result=(gateway_response.success?).tap do |success|
        if success
          self.mark_paid!
          return gateway_response
          #do we want to save the billing profile? if so do it here
        else
          self.transaction_declined!
        end
      end
      gateway_response
    end.last
  end

  def self.referers_for_paid(how_many)
    not_free.first(how_many).map{|o|
      [o.reference_number, o.created_at, o.referer_urls] unless o.referer_urls.blank?}.compact.flatten
  end

  def to_param
    reference_number
  end

  def display_state
    display=case self.state
              when "fully_refunded"
                "(REFUNDED)"
              when "charged_back"
                "(CHARGEBACK)"
              when "rejected"
                "(REJECTED)"
              else
                ""
            end
    # (is_test? ? "(TEST) " : "") + display
  end

  def is_deposit?
    Deposit == line_items.first.sellable.class if line_items.first
  end

  def is_reseller_tier?
    ResellerTier == line_items.first.sellable.class if line_items.first
  end

  def migrated_from
    v=V2MigrationProgress.find_by_migratable(self, :all)
    v.map(&:source_obj) if v
  end

  #the next 2 functions are for migration purposes
  #this function shows order that have order total amount that do not match their child
  #line_item totals
  def self.totals_mismatched
    includes(:line_items).all.select{|o|o.cents!=o.line_items.sum(:cents)}
  end

  #this function shows order that have order total amount are less then child
  #line_item totals and may result in in line_items that should not exist
  def self.with_too_many_line_items
    includes(:line_items).all.select{|o|o.cents<o.line_items.sum(:cents)}
  end

  def referer_urls
    visitor_token.trackings.non_ssl_com_referer.map(&:referer).map(&:url) if visitor_token
  end

  # We'll raise this exception in the case of an unsettled credit.
  class UnsettledCreditError < RuntimeError
    UNSETTLED_CREDIT_RESPONSE_REASON_CODE = '54'

    def self.match?( response )
      response.params['response_reason_code'] == UNSETTLED_CREDIT_RESPONSE_REASON_CODE
    end
  end

  # ============================================================================
  # Make available to customer
  # ============================================================================
  def make_available_total
    get_total_merchant_amount + get_funded_account_amount
  end

  def make_available_line(item, type=nil)
    order_total  = domains_adjustment? ? get_full_reprocess_amount : line_items.pluck(:cents).sum
    discount_amt = discount_amount(:items)
    total = if domains_adjustment?
      get_full_reprocess_amount
    else
      item.is_a?(LineItem) ? item.cents : item.amount
    end
    percent      = total.to_d/order_total.to_d
    discount     = (discount_amt.blank? || discount_amt.cents == 0) ? 0 : (discount_amt.cents * percent)
    funded       = get_funded_account_amount == 0 ? 0 : (get_funded_account_amount * percent)

    if type == :merchant
      total - (discount + funded)
    else
      total - discount
    end
  end

  def make_available_funded(item)
    order_total  = line_items.pluck(:cents).sum
    total        = item.is_a?(LineItem) ? item.cents : item.amount
    percent      = total.to_d/order_total.to_d
    get_funded_account_amount == 0 ? 0 : (get_funded_account_amount * percent)
  end

  # If order has been transfered from another team, then the originating team
  # should be credited. Lookup SystemAudit log for specific keywords
  # to determine originating order.
  def get_team_to_credit
    order_transferred = SystemAudit
      .where(target_type: 'Order', target_id: id)
      .where("notes LIKE ?", "%from team%")
      .order(created_at: :desc).last
    unless order_transferred.nil?
      from_team = order_transferred.notes.split.find {|str| str.include?('#')}
    end
    from_team = SslAccount.find_by(acct_number: from_team.gsub('#', '')) unless from_team.nil?
    from_team.nil? ? billable : from_team
  end

  # ============================================================================
  # REFUND (utilizes 3 merchants, Stripe, PaypalExpress and Authorize.net)
  # ============================================================================
  def refund_merchant(amount, reason, user_id)
    o  = get_order_charged
    ot = o.transactions.last if (o && o.transactions.last)
    new_refund = nil
    if o && payment_refundable?
      params   = {
        merchant: get_merchant,
        user_id:  user_id,
        order:    o,
        amount:   amount,
        reason:   reason,
        order_transaction: ot
      }
      new_refund = Refund.refund_merchant(params)
    end

    unless invoice_payment?
      if merchant_fully_refunded?
        full_refund! unless fully_refunded?
        if certificate_orders.any?
          cached_certificate_orders.each {|co| co.refund! unless co.refunded?}
        end
      else
        partial_refund! unless partially_refunded?
      end
    end

    SystemAudit.create(
        owner:  User.find_by_id(user_id),
        target: o,
        action: "Refund #{new_refund.id} created for order #{o.reference_number}. It is now #{o.current_state}",
        notes:  "Originating order is #{self.reference_number}."
    )
    new_refund
  end

  def get_merchant
    o = get_order_charged
    return 'na'         if o.payment_not_refundable?
    return 'paypal'     if o.payment_paypal?
    return 'stripe'     if o.payment_stripe?
    return 'authnet'    if o.payment_authnet?
    return 'no_payment' if o.payment_not_required?
    return 'zero_amt'   if o.payment_zero?
    return 'funded'     if o.payment_funded_account_partial? || o.payment_funded_account?
    return 'other'
  end

  def get_order_charged
    deducted_from_id ? Order.find_by_id(deducted_from_id) : self
  end

  def get_total_merchant_amount
    merchant = get_merchant
    o = get_order_charged
    return (o.transactions.map(&:cents).sum) if o && %w{stripe authnet}.include?(merchant)
    return o.cents if o && merchant == 'paypal'
    if o
      if %w{no_payment zero_amt funded}.include?(merchant)
        0
      else
        o.cents
      end
    else
      0
    end
  end

  def get_full_reprocess_amount
    cur_amount = cents != get_total_merchant_amount ? cents : get_total_merchant_amount
    cur_amount + get_funded_account_amount
  end

  def get_full_reprocess_format
    Money.new(get_full_reprocess_amount).format
  end

  def get_paid_reprocess_amount
    get_total_merchant_amount
  end

  def get_funded_account_order
    # order for funded account withdrawal
    Order.where('description LIKE ?', "%Funded Account Withdrawal%")
      .where('notes LIKE ?', "%#{reference_number}%").last
  end

  def get_funded_account_amount
    # order was partially paid by funded account?
    found = get_funded_account_order
    found ? found.cents : 0
  end

  def get_surplus_amount
    # covered order amount and suplus credited to funded account?
    get_total_merchant_amount - (cents - get_funded_account_amount)
  end

  def get_total_merchant_refunds
    refunds.where(status: 'success').map(&:amount).sum
  end

  def payment_refundable?
    target = get_merchant
    !target.blank? && %w{stripe paypal authnet}.include?(target)
  end

  def payment_not_required?
    state == 'payment_not_required'
  end

  def payment_not_refundable?
    po_number || quote_number
  end

  def payment_zero?
    [billable_type, notes, po_number, quote_number].compact.empty? &&
      cents == 0 && !payment_not_required?
  end

  def payment_funded_account_partial?
    description.include?('Funded Account Withdrawal')
  end

  def payment_funded_account?
    billing_profile_id.nil? &&
      po_number.nil? &&
      quote_number.nil? &&
      ( notes.blank? || funded_account_w_notes? ) &&
      transactions.empty? &&
      deducted_from_id.nil? &&
      state == 'paid'
  end

  def funded_account_w_notes?
    !notes.blank? && (
      notes.include?('Reprocess UCC') ||
      notes.include?('Initial CSR') ||
      notes.include?('Renewal UCC') ||
      notes.include?('monthly invoice') ||
      notes.include?('daily invoice')
    )
  end

  def payment_stripe?
    !payment_not_refundable? && transactions.any? &&
      !transactions.last.reference.blank? &&
      transactions.last.reference.include?('ch_')
  end

  def payment_authnet?
    !payment_not_refundable? && transactions.any? &&
      !transactions.last.reference.blank? &&
      transactions.last.reference.include?('#purchase')
  end

  def payment_paypal?
    !payment_not_refundable? && !notes.blank? && notes.include?('paidviapaypal')
  end

  # this builds non-deep certificate_orders(s) from the cookie params
  def self.certificates_order(options)
    options[:certificates].compact.each do |c|
      next if c[ShoppingCart::PRODUCT_CODE]=~/\Areseller_tier/
      if certificate = Certificate.for_sale.find_by_product(c[ShoppingCart::PRODUCT_CODE])
        if certificate.is_free?
          qty=c[ShoppingCart::QUANTITY].to_i > options[:max_free] ? options[:max_free] : c[ShoppingCart::QUANTITY].to_i
        else
          qty=c[ShoppingCart::QUANTITY].to_i
        end
        certificate_order = CertificateOrder.new(
            :server_licenses => c[ShoppingCart::LICENSES],
            :duration => c[ShoppingCart::DURATION],
            :quantity => qty)
        certificate_order.add_renewal c[ShoppingCart::RENEWAL_ORDER]
        certificate_order.certificate_contents.build :domains => c[ShoppingCart::DOMAINS]
        unless options[:current_user].blank?
          options[:current_user].ssl_account.clear_new_certificate_orders
          certificate_order.ssl_account=current_user.ssl_account
          next unless options[:current_user].ssl_account.can_buy?(certificate)
        end
        #adjusting duration to reflect number of days validity
        certificate_order = setup_certificate_order(certificate: certificate, certificate_order: certificate_order)
        options[:certificate_orders] << certificate_order if certificate_order.valid?
      end
    end
    options[:certificate_orders]
  end

  def preferred_migrated_from_v2?
    Rails.cache.fetch("#{cache_key}/migrated_from_v2") do
      created_at < Time.at(1317279546) # last order in production that was migrated
    end
  end
  alias_method "preferred_migrated_from_v2".to_sym, "preferred_migrated_from_v2?".to_sym

  # builds out certificate_order at a deep level by building SubOrderItems for each certificate_order
  def self.setup_certificate_order(options)
    certificate = options[:certificate]
    certificate_order = options[:certificate_order]
    days = options[:duration] || certificate_order.duration
    duration = certificate&.duration_in_days(days)
    certificate_order&.certificate_content&.duration = duration
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
        additional_domains = (certificate_order.domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so                 = SubOrderItem.new(:product_variant_item=>pd[0],
                                              :quantity            =>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
                                              :amount              =>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        certificate_order.sub_order_items << so
        # calculate wildcards by subtracting their total from additional_domains
        wildcards = 0
        if certificate.allow_wildcard_ucc? and !certificate_order.domains.blank?
          wildcards = certificate_order.domains.find_all{|d|d =~ /\A\*\./}.count
          additional_domains -= wildcards
        end
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
                                :quantity            =>additional_domains,
                                :amount              =>pd[1].amount*additional_domains)
          certificate_order.sub_order_items << so
        end
        if wildcards > 0
          so = SubOrderItem.new(:product_variant_item=>pd[2],
                                :quantity            =>wildcards,
                                :amount              =>pd[2].amount*wildcards)
          certificate_order.sub_order_items << so
        end

        certificate_order.wildcard_count = wildcards
        certificate_order.nonwildcard_count = (certificate_order.domains.try(:size) || 0) - wildcards
      end
    end
    unless certificate.is_ucc?
      pvi = certificate.items_by_duration.find { |item| item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
                             :amount              =>pvi.amount)
      certificate_order.sub_order_items << so
    end
    certificate_order.amount = certificate_order.sub_order_items.map(&:amount).sum
    certificate_order&.certificate_contents[0]&.certificate_order = certificate_order
    certificate_order
  end

  def primary_user
    billable.primary_user
  end

  def is_test?
    certificate_orders.is_test.count > 0
  end

  # This is the required step to save certificate_orders to this order
  # creates certificate_orders (and 'support' objects ie certificate_contents and sub_order_items)
  # to be save to line_item.
  def add_certificate_orders(certificate_orders)
    self.amount=0 #will be adding the line_items below
    certificate_orders.select{|co|co.is_a? CertificateOrder}.each do |cert|
      cert.quantity.times do |i|
        new_cert = CertificateOrder.new(cert.attributes)
        cert.sub_order_items.each {|soi|
          new_cert.sub_order_items << SubOrderItem.new(soi.attributes)
        }
        cert.certificate_contents.each {|cc|
          cc_tmp = CertificateContent.new(cc.attributes)
          cc_tmp.certificate_order = new_cert
          new_cert.certificate_contents << cc_tmp
        }
        new_cert.line_item_qty = cert.quantity if(i==cert.quantity-1)
        new_cert.preferred_payment_order = 'prepaid'
        #the line blow was concocted because a simple assignment resulted in
        #the certificate_order coming up nil on each certificate_content
        #and failing the has_csr validation in the certificate_order
        #        new_cert.certificate_contents.clear
        #        cert.certificate_contents.each {|cc|
        #          cc_tmp = cc.dclone
        #          cc_tmp.certificate_order = new_cert
        #          new_cert.certificate_contents << cc_tmp} unless cert.certificate_contents.blank?
        self.line_items.build :sellable=>new_cert
      end
    end
  end

  def invoice_bill_to_str
    invoice = Invoice.find_by(order_id: id)
    o       = get_order_charged
    bt      = invoice.nil? ? o.billing_profile : invoice
    if bt
      addr = []
      addr << bt.company unless bt.company.blank?
      addr << "#{bt.first_name} #{bt.last_name}"
      addr << bt.address_1
      addr << bt.address_2 unless bt.address_2.blank?
      addr << "#{bt.city}, #{bt.state}, #{bt.postal_code}"
      addr << bt.country
      addr
    else
      []
    end
  end

  def original_order?
    self.class == Order
  end

  private

  def domains_adjustment_notice
    if domains_adjustment? and Settings.invoice_notify
      Assignment.users_can_manage_invoice(billable).each do |u|
        OrderNotifier.domains_adjustment_new(user: u, order: self).deliver_now
      end
    end
  end

  def gateway
    OrderTransaction.gateway
  end

  def payment_failed(response)
    raise Payment::AuthorizationError.new(response.message)
  end

  def options_for_payment(options = {})
    {:order_id => self.id, :customer => self.billable_id}.merge(options)
  end

  def determine_description
    self.description ||= SSL_CERTIFICATE
    #causing issues with size of description for larger orders
#    self.description ||= self.certificate_orders.
#      map(&:description).join(" : ")
  end

  def cancel_order
    current_invoice = invoice
    line_items.each {|li| li.sellable_unscoped.cancel!}
    update(canceled_at: Time.now, invoice_id: nil)
    if current_invoice && current_invoice.orders.empty?
      current_invoice.destroy
    end
  end
end
