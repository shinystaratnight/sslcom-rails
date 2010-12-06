class FundedAccount < ActiveRecord::Base
  using_access_control
  belongs_to :ssl_account

  money :amount, :currency => false

  validates_presence_of :ssl_account

  attr_accessor :funding_source
  attr_accessor :order_type
  attr_accessor_with_default :deduct_order, false

  NEW_CREDIT_CARD = "new credit card"

  def deduct_order?
    ["true", true].include? @deduct_order
  end
end
