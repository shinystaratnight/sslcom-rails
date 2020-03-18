# == Schema Information
#
# Table name: payments
#
#  id           :integer          not null, primary key
#  cents        :integer
#  cleared_at   :datetime
#  confirmation :string(255)
#  currency     :string(255)
#  lock_version :integer          default("0")
#  voided_at    :datetime
#  created_at   :datetime
#  updated_at   :datetime
#  address_id   :integer
#  order_id     :integer
#
# Indexes
#
#  index_payments_on_address_id  (address_id)
#  index_payments_on_cleared_at  (cleared_at)
#  index_payments_on_created_at  (created_at)
#  index_payments_on_order_id    (order_id)
#  index_payments_on_updated_at  (updated_at)
#

class Payment < ApplicationRecord
  class AuthorizationError < StandardError; end
  belongs_to :order
  belongs_to :address
  
  money :amount
  
  def capture
    response = ActiveMerchant::Billing::Base.default_gateway.capture(self.amount, self.confirmation)
    update_attributes :cleared_at => Time.now, :confirmation => response.authorization
  end
  
  def void!
    response = ActiveMerchant::Billing::Base.default_gateway.void(self.confirmation)
    raise response.message unless response.success?
    update_attribute :voided_at, Time.now
  end
  
end
