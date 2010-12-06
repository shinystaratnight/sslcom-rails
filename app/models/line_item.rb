class LineItem < ActiveRecord::Base
  belongs_to  :order
  belongs_to  :affiliate
  belongs_to  :sellable, :polymorphic => true
  
  money :amount
  
  # set #amount when adding sellable.  This method is aliased to <tt>sellable=</tt>.
  def sellable_with_price=(sellable)
    self.amount = sellable && sellable.price ? sellable.price : 0
    self.sellable_without_price = sellable
  end
  alias_method_chain :sellable=, :price

  def initialize(*params)
    super(*params)
    self.affiliate_payout_rate ||= 0.0
  end

  def affiliate_commission
    Money.new(affiliate_commission_price)
  end

  def affiliate_commission_price
    (affiliate and not affiliate_payout_rate.blank?) ?
        affiliate_payout_rate*amount.cents : 0
  end

  def studio_fee
    Money.new(studio_fee_rate*amount.cents)
  end

  def studio_payout
    Money.new((1-studio_fee_rate)*amount.cents)
  end

  def net_profit
    Money.new(net_profit_price)
  end

  def net_profit_price
    amount.cents-(affiliate_payout_rate*amount.cents+
        studio_fee_rate*amount.cents)
  end
end
