class Order < ActiveRecord::Base
  belongs_to :billable, :polymorphic => true
  belongs_to :address
  has_many :line_items, :dependent => :destroy
  has_many :payments
  
  money :amount
  before_create :total
  
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
    self.amount = line_items.inject(Money.new(0)) {|sum,l| sum + l.amount }
  end
  
  # TODO: Should this do more?
  def cancel!
    update_attribute :canceled_at, Time.now
  end
  
private

  def gateway
    ActiveMerchant::Billing::Base.default_gateway
  end

  def payment_failed(response)
    raise Payment::AuthorizationError.new(response.message)
  end

  def options_for_payment(options = {})
    {:order_id => self.id, :customer => self.billable_id}.merge(options)
  end


end