class Deposit < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false
  has_many    :orders, :through => :line_items, :include => :stored_preferences


  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end

  def order
    orders.last
  end
  
  protected

  def validate
    errors.add(:price, "must be greater than 0") if price.nil? or price.cents <= 0
  end
end
