class Refund < ApplicationRecord
  include ActiveMerchant::Billing

  belongs_to :order
  belongs_to :order_transaction
  belongs_to :user

  serialize  :merchant_response

  scope :failed,     -> {where(status: 'failed')}
  scope :successful, -> {where(status: 'success')}
  
  def self.refund_merchant(params)
    refund = Refund.new
    case params[:merchant]
      when 'stripe'
        refund.stripe_refund(params)
      when 'authnet'
        unsettled = refund.unsettled_transaction?(params)
        unsettled ? refund.authnet_void(params) : refund.authnet_refund(params)
      when 'paypal'
        refund.paypal_refund(params)
    end
    refund.duplicate_refund if refund.persisted?
    refund
  end
  
  def stripe_refund(params)
      stripe_params  = {
        charge:   get_reference(params),
        amount:   params[:amount],
        metadata: {
          reason:           params[:reason],
          requested_amount: params[:amount],
          user_id:          params[:user_id],
          order_id:         params[:order].id,
          order_trans_id:   params[:order_transaction].id
        }
      }
      begin
        refund = Stripe::Refund.create(stripe_params)
      rescue Stripe::CardError,
             Stripe::RateLimitError,
             Stripe::InvalidRequestError,
             Stripe::AuthenticationError,
             Stripe::APIConnectionError,
             Stripe::StripeError => e
        log_stripe_failure_response(e, params)
      else
        log_stripe_success_response(refund, params)
      end
  end
  
  def authnet_refund(params)
    response = authnet_gateway.refund(params[:amount], get_reference(params))
    update_from_response(params, response)
  end
  
  def authnet_void(params)
    # unsettled transaction, try void if purchse was made within 24 hours.
    response = authnet_gateway.void(get_reference(params))
    update_from_response(params, response)
  end
  
  def paypal_refund(params)
    response = paypal_gateway.refund(params[:amount], get_reference(params))
    update_from_response(params, response)
  end
  
  def unsettled_transaction?(params)
    end_time   = Time.parse(DateTime.now.to_s)
    start_time = Time.parse(params[:order].created_at.to_s)
    ((end_time - start_time)/3600) <= 24
  end
  
  def successful?
    status == 'success'
  end
  
  def duplicate_refund
    # If another order was deducted from this order (e.g.: Deposit), create a refund 
    # record for both orders.
    found = Order.where(deducted_from_id: order.id)
    if self.persisted? && found.any?
      copy = self.dup
      copy.update(order_id: found.last.id)
    end
  end
  
  private
  
  def get_reference(params)
    merchant = params[:merchant]
    return params[:order].notes.split.last.strip.delete('#paidviapaypal') if merchant == 'paypal'
    return params[:order_transaction].reference if %w{stripe authnet}.include?(merchant)
  end
  
  def parse_main_params(params)
    {
      merchant:          params[:merchant],
      amount:            params[:amount],
      user_id:           params[:user_id],
      order_transaction: params[:order_transaction],
      order:             params[:order],
      reason:            params[:reason],
      partial_refund:    partial_refund?(params)
    }
  end
  
  def partial_refund?(params)
    amt = params[:order_transaction] ? params[:order_transaction] : params[:order]
    params[:amount] < amt.cents
  end
  # 
  # Stripe Helpers
  # 
  def log_stripe_failure_response(e, params)
    self.update(
      parse_main_params(params).merge({
        status:  'failed',
        message: e.to_param,
        merchant_response: {
            stripe_charge_id:     get_reference(params),
            stripe_request_id:    e.request_id,
            stripe_error_class:   e.class.to_s,
            stripe_error_type:    e.json_body[:error][:type],
            stripe_error_message: e.to_param
        }
      })
    )
  end
  
  def log_stripe_success_response(refund, params)
    if refund.status == 'succeeded'
      self.update(
        parse_main_params(params).merge({
          status:            'success',
          reference:         refund.id,
          merchant_response: refund.to_hash
        })
      )
    end
  end
  # 
  # ActiveMerchant Helpers
  #
  def update_from_response(params, response)
    if response.success?
      log_success_response(params, response)
    else
      log_failure_response(params, response)
    end
  end
  
  def log_success_response(params, response)
    if response.success?
      self.update(
        parse_main_params(params).merge({
          status:           'success',
          reference:         response.authorization,
          merchant_response: response.params,
          test:              response.test
        })
      )
    end
  end
  
  def log_failure_response(params, response)
    unless response.success?
      self.update(
        parse_main_params(params).merge({
          status:            'failed',
          message:           response.message,
          merchant_response: response.params,
          test:              response.test
        })
      )
    end
  end
  
  def paypal_gateway
    s = ::Rails.application.secrets
    ActiveMerchant::Billing::PaypalExpressGateway.new(
      login:     s.paypal_username,
      password:  s.paypal_password,
      signature: s.paypal_signature
    )
  end
  
  def authnet_gateway
    s = ::Rails.application.secrets
    ActiveMerchant::Billing::AuthorizeNetGateway.new(
      login:    s.authorize_net_key,
      password: s.authorize_net_trans_id
    )
  end
end
