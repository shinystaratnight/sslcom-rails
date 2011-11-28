class OrderTransaction < ActiveRecord::Base
  belongs_to :order
  serialize :params
  serialize :avs
  serialize :cvv
  cattr_accessor :gateway
 
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
      process('purchase', amount) do |gw|
        gw.purchase(amount, credit_card, options)
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
      creds =
          case Rails.env
            when /production/i
              {:login    => Settings.p_authorize_net_key,
              :password => Settings.p_authorize_net_transaction_id}
            else
              {:login    => Settings.authorize_net_key,
              :password => Settings.authorize_net_transaction_id}
            end
      ActiveMerchant::Billing::AuthorizeNetGateway.new(creds)
    end
  end
end
