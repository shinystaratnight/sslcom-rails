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
    rescue => e
      log_failure(e, card_token)
    else
      log_charge_response(charge)
    end
  end
  
  def stripe_charge(amount, card_token, options = {})
    description = options[:description]
    Stripe::Charge.create(
      source:               card_token,
      amount:               amount.cents,
      description:          description,
      statement_descriptor: description[0..21], # can only be 22 chars long
      currency:             'usd',
      receipt_email:        'sales@ssl.com' #options[:owner_email]
    )
  end
  # Ceate Stripe card token if using an existing CC billing profile for purchase
  def create_card_token(credit_card, options = {})
    address = options[:billing_address]
    token = nil
    begin
      token = Stripe::Token.create(
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
    rescue => e
      log_failure(e, token)
    else
      token
    end
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
      account_number:      charge[:source][:last4],
      card_amount:         charge[:amount],
      card_fingerprint:    charge[:source].fingerprint
    }
  end
    
  def log_failure(e, card_token=nil)
    message = if e.class == Stripe::CardError
      "This transaction has been declined. #{e.message}"
    else
      'Something went wrong! The card was not charged.'
    end
    self.success   = false
    self.reference = nil
    self.message   = message
    self.params    = log_failure_error(e)
    self.test      = stripe_test?(card_token)
  end
  
  def log_failure_error(e)
    err = e.json_body[:error]
    {
      status:       e.http_status,
      type:         err[:type],
      charge_id:    err[:charge],
      code:         err[:code],
      decline_code: err[:decline_code],
      param:        err[:param], 
      message:      err[:message],
      message_more: "#{e.class.to_s} - #{err[:code]}, #{err[:message]}"
    }
  end
  
  def stripe_test?(stripe_object)
    stripe_object = Stripe::Token.retrieve(stripe_object) if stripe_object.is_a?(String)
    !stripe_object[:livemode]
  end
end
