require 'monitor'
require 'bigdecimal'

class Order < ActiveRecord::Base
  include V2MigrationProgressAddon
  belongs_to  :billable, :polymorphic => true
  belongs_to  :address
  belongs_to  :billing_profile
  belongs_to  :deducted_from, class_name: "Order", foreign_key: "deducted_from_id"
  belongs_to  :visitor_token
  has_many    :line_items, dependent: :destroy
  has_many    :payments
  has_many    :transactions, class_name: 'OrderTransaction', dependent: :destroy
  has_many    :discounts, :as => :discountable

  money :amount
  before_create :total, :determine_description
  after_create :generate_reference_number, :commit_discounts

  #is_free? is used to as a way to allow orders that are not charged (ie cent==0)
  attr_accessor  :is_free, :receipt, :deposit_mode, :temp_discounts

  after_initialize do
    return unless new_record?
    self.is_free ||= false
    self.receipt ||= false
    self.deposit_mode ||= false
  end

  SSL_CERTIFICATE = "SSL Certificate Order"

  #go live with this
#  default_scope includes(:line_items).where({line_items:
#    [:sellable_type !~ ResellerTier.to_s]}  & (:billable_id - [13, 5146])).order('created_at desc')
  #need to delete some test accounts
  default_scope includes(:line_items).where{state != 'payment_declined'}.order(:created_at.desc)

  scope :not_new, lambda {
    joins{line_items.sellable(CertificateOrder)}.
        where{line_items.sellable(CertificateOrder).workflow_state=='paid'}
  }

  scope :not_test, lambda {
    joins{line_items.sellable(CertificateOrder)}.
        where{(line_items.sellable(CertificateOrder).is_test==nil) |
        (line_items.sellable(CertificateOrder).is_test==false)}
  }

  scope :search, lambda {|term|
    where{reference_number =~ "#{term}"}
  }

  scope :not_free, lambda{
    not_new.where :cents.gt=>0
  }

  scope :tracked_visitor, where{visitor_token_id != nil}

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
      self.not_free.sum(:cents)*0.01
    end
  end

  preference :migrated_from_v2, :default=>false

  def self.range_amount(start, finish)
    amount = BigDecimal.new(range(start, finish).amount.to_s)
    rounded = (amount * 100).round / 100
    '%.02f' % rounded
  end

  def authorize(credit_card, options = {})
    response = gateway.authorize(self.amount, credit_card, options_for_payment(options))
    if response.success?
      self.payments.build(:amount => self.amount, :confirmation => response.authorization,
        :address => options[:billing_address])
    else
      payment_failed(response)
    end
  end

  def discount_amount
    t=0
    unless id
      temp_discounts.each do |d|
        d=Discount.find(d)
        d.apply_as=="percentage" ? t+=(d.value.to_f*amount.cents) : t+=(d.value.to_i*100)
      end unless temp_discounts.blank?
    else
      discounts.each do |d|
        d.apply_as=="percentage" ? t+=(d.value.to_f*amount.cents) : t+=(d.value.to_i*100)
      end unless discounts.empty?
    end
    Money.new(t)
  end

  def lead_up_to_sale
    u = billable.users.last
    history = u.browsing_history("01/01/2000", created_at, "desc")
    history = history.compact.sort{|x,y|x[1][0]<=>y[1][0]}.last if history.count > 1
    history.shift
    (["Order for amount #{amount} was made on #{created_at}"]<<history).flatten
  end

  def pay(credit_card, options = {})
    response = gateway.purchase(self.final_amount, credit_card, options_for_payment(options))
    if response.success?
      self.payments.build(:amount => self.amount,
          :confirmation => response.authorization,
          :cleared_at => Time.now,
          :address => options[:billing_address]).tap do |payment|
        self.paid_at = Time.now
        payment.save && self.save unless new_record?
      end
    else
      payment_failed(response)
    end
  end
    
  def total
    self.amount = line_items.inject(0.to_money) {|sum,l| sum + l.amount }
  end

  def final_amount
    Money.new(amount.cents)-discount_amount
  end
  
  # TODO: Should this do more?
  def cancel!
    update_attribute :canceled_at, Time.now
  end

  include Workflow
  workflow_column :state

  workflow do
    state :pending do
      event :give_away, transitions_to: :payment_not_required
      event :payment_authorized, transitions_to: :authorized
      event :transaction_declined, :transitions_to => :payment_declined
    end

    state :authorized do
      event :payment_captured, transitions_to: :paid
      event :transaction_declined, transitions_to: :authorized
    end

    state :paid do
      event :full_refund, transitions_to: :fully_refunded
    end

    state :fully_refunded

    state :payment_declined do
      event :give_away, transitions_to: :payment_not_required
      event :payment_authorized, transitions_to: :authorized
      event :transaction_declined, :transitions_to => :payment_declined

    end

    state :payment_not_required

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
  def number
    SecureRandom.base64(32)
  end
  # END number

  # BEGIN authorize_payment
  def authorize_payment(credit_card, options = {})
    options[:order_id] = number
    transaction do

      authorization = OrderTransaction.authorize(amount, credit_card, options)
      transactions.push(authorization)

      if authorization.success?
        payment_authorized!
      else
        transaction_declined!
        errors[:base]<<(authorization.message)
      end

      authorization
    end
  end
  # END authorize_payment

  # BEGIN capture_payment
  def capture_payment(options = {})
    transaction do
      capture = OrderTransaction.capture(final_amount, authorization_reference, options)
      transactions.push(capture)
      if capture.success?
        payment_captured!
      else
        transaction_declined!
        errors[:base] << capture.message
      end

      capture
    end
  end
  # END capture_payment

  # BEGIN purchase
  def purchase(credit_card, options = {})
    options[:order_id] = number
    transaction do

      authorization = OrderTransaction.purchase(final_amount, credit_card, options)
      transactions.push(authorization)

      if authorization.success?
        payment_authorized!
      else
        transaction_declined!
        errors[:base] << authorization.message
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
      discounts<<Discount.find(td)
    end unless temp_discounts.empty?
    temp_discounts=nil
  end

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
#          ActiveRecord::Base.find_from_model_and_id(pr))
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
      if defined?(::GATEWAY_TEST_CODE)
        params.merge!(card_number: "4222222222222")
        self.amount = ::GATEWAY_TEST_CODE if defined?(::GATEWAY_TEST_CODE)
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

  def is_deposit?
    Deposit == line_items.first.sellable.class
  end

  def is_reseller_tier?
    ResellerTier == line_items.first.sellable.class
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

  def refund(refund_amount=self.amount)
    card_num = billing_profile.card_number
    transaction do
      if refund_amount != self.amount
        # Different amounts: only a CREDIT will do
        response = OrderTransaction.credit(
                  refund_amount,
                  self.transactions.last.reference,
                  :card_number => card_num)
        if UnsettledCreditError.match?( response )
          raise UnsettledCreditError
        end
      else
        # Same amount: try a VOID first, falling back to CREDIT if that fails
        response = gateway.void( self.transactions.last.reference )

        unless response.success?
          response = OrderTransaction.credit(
            refund_amount, self.transactions.last.reference, :card_number => card_num)
        end
      end
      transactions.push(response)
      full_refund!
      response
    end
  end



  private

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
#    self.description ||= self.line_items.map(&:sellable).
#      map(&:description).join(" : ")
  end
end