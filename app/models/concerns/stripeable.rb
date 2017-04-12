module Stripeable
  extend ActiveSupport::Concern
  
  class_methods do
    def stripe_purchase(amount, credit_card, options = {})
      card_token = options[:stripe_card_token]
      @ot        = OrderTransaction.new
      @ot.action = 'purchase'
      @ot.amount = amount.to_s
      card_token = @ot.create_card_token(credit_card, options) unless card_token
      @ot.create_charge(amount, card_token, options)
      @ot
    end
  end
  
  def create_charge(amount, card_token, options = {})
    begin
      charge = stripe_charge(amount, card_token, options)
    rescue Stripe::CardError => e
      log_failure(card_token, e, 'Stripe::CardError - card is declined.')
    rescue Stripe::RateLimitError => e
      log_failure(card_token, e, 'Stripe::RateLimitError - too many requests made to the API too quickly.')
    rescue Stripe::InvalidRequestError => e
      log_failure(card_token, e, 'Stripe::InvalidRequestError - invalid parameters were supplied.')
    rescue Stripe::AuthenticationError => e
      log_failure(card_token, e, 'Stripe::AuthenticationError - authentication with Stripes API failed.')
    rescue Stripe::APIConnectionError => e
      log_failure(card_token, e, 'Stripe::APIConnectionError - network communication with Stripe failed.')
    rescue Stripe::StripeError => e
      log_failure(card_token, e, 'Stripe::StripeError')
    else
      log_charge_response(charge)
    end
  end
  
  def stripe_charge(amount, card_token, options = {})
    Stripe::Charge.create(
      source:               card_token,
      amount:               amount.cents,
      description:          options[:description],
      statement_descriptor: options[:description],
      currency:             'usd',
      receipt_email:        'stripe_email@domain.com',
    )
  end
  # Ceate Stripe card token if using an existing CC billing profile for purchase
  def create_card_token(credit_card, options = {})
    address = options[:billing_address]
    Stripe::Token.create(
      card: {
        name:          "#{credit_card.first_name} #{credit_card.last_name}",
        number:        credit_card.number,
        exp_month:     credit_card.month,
        exp_year:      credit_card.year,
        cvc:           credit_card.verification_value,
        address_line1: address[:street1],
        address_city:  address[:locality],
        address_state: address[:region],
        address_zip:   address[:postal_code]
      },
    )
  end
  
  def log_charge_response(charge)
    self.reference = charge[:id]
    self.success   = charge[:status] == 'succeeded' && charge[:paid]
    self.message   = 'This transaction has been approved'
    self.params    = log_charge_response_params(charge)
    self.test      = stripe_test?(charge)
    self.cvv       = charge[:source][:cvc_check]
  end
  
  def log_charge_response_params(charge)
    {
      merchant:            'Stripe',
      stripe_charge_id:    charge[:id],
      paid:                charge[:paid],
      outcome:             charge[:outcome].to_h,
      balance_transaction: charge[:balance_transaction],
      created:             charge[:created],
      card_id:             charge[:source].id,
      card_amount:         charge[:amount],
      card_fingerprint:    charge[:source].fingerprint
    }
  end
    
  def log_failure(card_token, e, error_message)
    more = (e.class == Stripe::CardError) ? 'Your card was declined.' : 'The card was not charged.'
    self.success   = false
    self.reference = nil
    self.message   = "Something went wrong! #{more}"
    self.params    = log_failure_error(e, error_message)
    self.test      = stripe_test?(card_token)
  end
  
  def log_failure_error(e, error_message)
    err                   = e.json_body[:error]
    params                = {}
    params[:status]       = e.http_status
    params[:type]         = err[:type]
    params[:charge_id]    = err[:charge]
    params[:code]         = err[:code]         if err[:code]
    params[:decline_code] = err[:decline_code] if err[:decline_code]
    params[:param]        = err[:param]        if err[:param]
    params[:message]      = err[:message]      if err[:message]
    params[:message_more] = error_message
    params
  end
  
  def stripe_test?(stripe_object)
    stripe_object = Stripe::Token.retrieve(stripe_object) if stripe_object.is_a?(String)
    !stripe_object[:livemode]
  end
end
