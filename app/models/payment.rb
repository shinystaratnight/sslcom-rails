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
