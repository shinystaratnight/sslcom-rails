# == Schema Information
#
# Table name: deposits
#
#  id             :integer          not null, primary key
#  amount         :float(24)
#  credit_card    :string(255)
#  full_name      :string(255)
#  last_digits    :string(255)
#  payment_method :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class Deposit < ApplicationRecord
  acts_as_sellable :cents => :amount, :currency => false
  has_many    :orders, ->{includes(:stored_preferences)}, :through => :line_items


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
