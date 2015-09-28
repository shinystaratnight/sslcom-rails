class PaypalExpressController < ApplicationController
  before_filter :assigns_gateway, :setup_certificate_orders

  include ActiveMerchant::Billing
  include ApplicationHelper, OrdersHelper, PaypalExpressHelper

  def checkout
    total_as_cents, setup_purchase_params = get_setup_purchase_params current_order, request
    setup_response = @gateway.setup_purchase(total_as_cents, setup_purchase_params)
    redirect_to @gateway.redirect_url_for(setup_response.token)
  end

  def review
    if params[:token].nil?
      redirect_to home_url, :notice => 'Woops! Something went wrong!'
      return
    end

    gateway_response = @gateway.details_for(params[:token])

    unless gateway_response.success?
      redirect_to home_url, :notice => "Sorry! Something went wrong with the Paypal purchase. Here's what Paypal said: #{gateway_response.message}"
      return
    end

    @order_info = get_order_info gateway_response, current_order
  end

  def purchase
    if params[:token].nil? or params[:payer_id].nil?
      redirect_to home_url, :notice => "Sorry! Something went wrong with the Paypal purchase. Please try again later."
      return
    end

    total_as_cents, purchase_params = get_purchase_params current_order, request, params
    purchase = @gateway.purchase total_as_cents, purchase_params

    if purchase.success?
      # you might want to destroy your cart here if you have a shopping cart
      notice = "Thanks! Your purchase is now complete!"
    else
      notice = "Woops. Something went wrong while we were trying to complete the purchase with Paypal. Btw, here's what Paypal said: #{purchase.message}"
    end

    redirect_to root_url, :notice => notice
  end

  private
  def assigns_gateway
    creds = Settings.paypal_express.send(Rails.env =~ /production/ ? :production : :development)
    @gateway ||= PaypalExpressGateway.new(
        :login => creds.username,
        :password => creds.password,
        :signature => creds.signature
    )
  end
end
