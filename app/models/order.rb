require 'monitor'

class Order < ActiveRecord::Base
  belongs_to  :billable, :polymorphic => true
  belongs_to  :address
  belongs_to  :billing_profile
  belongs_to  :deducted_from, :class_name => "Order",
    :foreign_key => "deducted_from_id"
  has_many    :line_items, :dependent => :destroy
  has_many    :payments
  has_many    :transactions, :class_name => 'OrderTransaction',
                :dependent => :destroy
  
  money :amount
  before_create :total, :determine_description
  after_create :generate_reference_number
  #is_free? is used to as a way to allow orders that are not charged (ie cent==0)
  attr_accessor_with_default  :is_free, false
  attr_accessor_with_default  :receipt, false
  attr_accessor_with_default  :deposit_mode, false

  SSL_CERTIFICATE = "SSL Certificate Purchase"

  default_scope :order => 'orders.created_at DESC'
  named_scope :search, lambda {|term|
    {:conditions => ["reference_number #{SQL_LIKE} ?", '%'+term+'%']}
  }

  preference  :migrated_from_v2, :default=>false
  
  def authorize(credit_card, options = {})
    response = gateway.authorize(self.amount, credit_card, options_for_payment(options))
    if response.success?
      self.payments.build(:amount => self.amount, :confirmation => response.authorization,
        :address => options[:billing_address])
    else
      payment_failed(response)
    end
  end

  def pay(credit_card, options = {})
    response = gateway.purchase(self.amount, credit_card, options_for_payment(options))
    if response.success?
      returning self.payments.build(:amount => self.amount,
          :confirmation => response.authorization,
          :cleared_at => Time.now,
          :address => options[:billing_address]) do |payment|
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
  
  # TODO: Should this do more?
  def cancel!
    update_attribute :canceled_at, Time.now
  end

  # BEGIN acts_as_state_machine
  acts_as_state_machine :initial => :pending

  state :pending
  state :authorized
  state :paid
  state :payment_declined

  event :payment_authorized do
    transitions :from => :pending,
                :to   => :authorized

    transitions :from => :payment_declined,
                :to   => :authorized
  end

  event :payment_captured do
    transitions :from => :authorized,
                :to   => :paid
  end

  event :transaction_declined do
    transitions :from => :pending,
                :to   => :payment_declined

    transitions :from => :payment_declined,
                :to   => :payment_declined

    transitions :from => :authorized,
                :to   => :authorized
  end
  # END acts_as_state_machine

  # BEGIN number
  def number
    ActiveSupport::SecureRandom.base64(32)
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
        errors.add_to_base(authorization.message)
      end

      authorization
    end
  end
  # END authorize_payment

  # BEGIN capture_payment
  def capture_payment(options = {})
    transaction do
      capture = OrderTransaction.capture(amount, authorization_reference, options)
      transactions.push(capture)
      if capture.success?
        payment_captured!
      else
        transaction_declined!
        errors.add_to_base(capture.message)
      end

      capture
    end
  end
  # END capture_payment

  # BEGIN purchase
  def purchase(credit_card, options = {})
    options[:order_id] = number
    transaction do

      authorization = OrderTransaction.purchase(amount, credit_card, options)
      transactions.push(authorization)

      if authorization.success?
        payment_authorized!
      else
        transaction_declined!
        errors.add_to_base(authorization.message)
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
      update_attribute :reference_number, ActiveSupport::SecureRandom.hex(2)+
        '-'+Time.now.to_i.to_s(32)
  end

  def is_free?
    @is_free.try(:eql, true) || (preferred_migrated_from_v2==true || cents==0)
  end

  def self.cart_items(session, cookies)
    session[:cart_items] = []
    session[:affiliates_credits] = []
    unless SERVER_SIDE_CART
      new_cookie = cookies[:cart]
      new_aid_li_cookie = cookies[:aid_li]
      affiliates_credits = cookies[:aid_li].split(/:/) unless cookies[:aid_li].blank?
      cookies[:cart].split(/:/).each_with_index{|line_item, i|
        coa = line_item.split(/,/)
        if (coa.count > 1 && Certificate.find_by_product(coa.first)) ||
          ActiveRecord::Base.find_from_model_and_id(line_item)
          session[:cart_items] << line_item
          session[:affiliates_credits] << affiliates_credits[i]
        else
          new_cookie.sub!(line_item+":", "")
          new_aid_li_cookie.sub!(affiliates_credits[i]+":","")
          @change_cookie = true
        end
      } unless cookies[:cart].blank?
      if @change_cookie
        cookies.delete :cart
        cookies[:cart] = {:value=>new_cookie, :path => "/", 
          :expires => AppConfig.cart_cookie_days.to_i.days.from_now}
        cookies.delete :aid_li
        cookies[:aid_li] = {:value=>new_aid_li_cookie, :path => "/",
          :expires => AppConfig.affiliate_cookie_days.to_i.days.from_now}
      end
    end
  end

  def to_param
    reference_number
  end

  def is_deposit?
    Deposit == line_items.first.sellable.class
  end

  def migrated_from
    v=V2MigrationProgress.find_by_migratable(self, :all)
    v.map(&:source_obj) if v
  end


  private

  def gateway
    #ActiveMerchant::Billing::Base.default_gateway
    ActiveMerchant::Billing::AuthorizeNetGateway.new(
      :login    => '9jFL5k9E',
      :password => '8b3zEL5H69sN4Pth'
    )
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