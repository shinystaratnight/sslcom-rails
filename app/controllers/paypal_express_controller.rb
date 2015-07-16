class PaypalExpressController < ApplicationController
  before_filter :assigns_gateway

  include ActiveMerchant::Billing
  include ApplicationHelper, OrdersHelper, PaypalExpressHelper

  def checkout
    total_as_cents, setup_purchase_params = get_setup_purchase_params current_order, request
    setup_response = @gateway.setup_purchase(total_as_cents, setup_purchase_params)
    redirect_to @gateway.redirect_url_for(setup_response.token)
  end

  private
  def assigns_gateway
    @gateway ||= PaypalExpressGateway.new(
        :login => Settings.paypal_express_username,
        :password => Settings.paypal_express_password,
        :signature => Settings.paypal_express_signature
    )
  end
end
