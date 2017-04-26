class OrderTransaction < ActiveRecord::Base
  include Stripeable
  
  belongs_to  :order
  has_many    :renewal_attempts
  has_many    :refunds, dependent: :destroy

  serialize :params
  serialize :avs
  serialize :cvv
  cattr_accessor :gateway

  scope :paid_successfully, lambda{
    where{(success == true) & (amount > 0)}
  }
 
  scope :not_free, lambda{
    where{amount > 0}
  }

  class << self
    def authorize(amount, credit_card, options = {})
      process('authorization', amount) do |gw|
        gw.authorize(amount, credit_card, options)
      end
    end
    
    def capture(amount, authorization, options = {})
      process('capture', amount) do |gw|
        gw.capture(amount, authorization, options)
      end
    end
    
    def purchase(amount, credit_card, options = {})
      if amount.cents==0.0
        ActiveMerchant::Billing::Response.new(true, "This transaction has been approved")
      else
        if BillingProfile.gateway_stripe?
          OrderTransaction.stripe_purchase(amount, credit_card, options)
        else
          process('purchase', amount){|gw| gw.purchase(amount, credit_card, options)}
        end
      end
    end

    def credit(amount, ref, last_four)
      process('credit', amount) do |gw|
        gw.credit(amount, ref, last_four)
      end
    end

    private
    
    def process(action, amount = nil)
      result = OrderTransaction.new
      result.amount = amount.to_s
      result.action = action
    
      begin
        response = yield gateway
    
        result.success   = response.success?
        result.reference = response.authorization
        result.message   = response.message
        result.params    = response.params
        result.test      = response.test?
        result.avs       = response.avs_result
        result.cvv       = response.cvv_result
      rescue ActiveMerchant::ActiveMerchantError => e
        result.success   = false
        result.reference = nil
        result.message   = e.message
        result.params    = {}
        result.test      = gateway.test?
      end
      
      result
    end

    def gateway
      #ActiveMerchant::Billing::Base.default_gateway
      unless BillingProfile.gateway_stripe?
        s = ::Rails.application.secrets
        ActiveMerchant::Billing::AuthorizeNetGateway.new(
          login:    s.authorize_net_key,
          password: s.authorize_net_trans_id
        )
      end
    end
  end
end
