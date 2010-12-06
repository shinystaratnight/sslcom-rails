class Deposit < ActiveRecord::Base
  acts_as_sellable :cents => :amount, :currency => false

  def price=(amount)
    self.amount = amount.gsub(/\./,"").to_i
  end
  
  protected

  def validate
    errors.add(:price, "must be greater than 0") if price.nil? or price.cents <= 0
  end
end
