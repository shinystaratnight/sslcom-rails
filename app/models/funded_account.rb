class FundedAccount < ActiveRecord::Base
  using_access_control
  belongs_to :ssl_account

  money :amount, :currency => false

  validates_presence_of :ssl_account

  attr_accessor :funding_source, :order_type, :deduct_order, :target_amount

  after_initialize do
    self.deduct_order ||= false if new_record?
  end

  NEW_CREDIT_CARD = "new credit card"
  PAYPAL = "paypal"

  def deduct_order?
    ["true", true].include? @deduct_order
  end

  def add_cents(cents)
    FundedAccount.update_counters id, cents: cents
  end
end
