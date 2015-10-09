class PaypalExpressController < ApplicationController
  before_filter :assigns_gateway, :setup_certificate_orders

  include ActiveMerchant::Billing
  include ApplicationHelper, OrdersHelper, PaypalExpressHelper

  def item_to_buy
    params[:make_deposit] ? make_deposit : current_order
  end

  def make_deposit
    account = current_user.ssl_account || User.new.build_ssl_account
    account.purchase Deposit.new({amount: params[:amount],payment_method: 'paypal'})
  end

  def checkout
    unless current_user
      @user = User.new(params[:user])
      if  @user.valid?
        save_user
      else
        respond_to do |format|
          format.html { render "orders/new" }
        end and return
      end
    end
    total_as_cents, setup_purchase_params = get_setup_purchase_params item_to_buy, request
    setup_response = @gateway.setup_purchase(total_as_cents, setup_purchase_params)
    redirect_to @gateway.redirect_url_for(setup_response.token)
  end

  def review
    if params[:token].nil?
      redirect_to root_url, :notice => 'Woops! Something went wrong!'
      return
    end

    gateway_response = @gateway.details_for(params[:token])

    unless gateway_response.success?
      redirect_to root_url, :notice => "Sorry! Something went wrong with the Paypal purchase. Here's what Paypal said: #{gateway_response.message}"
      return
    end

    @order_info = get_order_info gateway_response, item_to_buy
  end

  def purchase
    if params[:token].nil?
      redirect_to orders_url, :notice => "Sorry! Something went wrong with the Paypal purchase. Please try again later."
      return
    end

    total_as_cents, purchase_params = get_purchase_params @gateway.details_for(params[:token]), request, params
    purchase = @gateway.purchase total_as_cents, purchase_params

    if purchase.success?
      # you might want to destroy your cart here if you have a shopping cart
      if purchase_params[:items][0][:name]=~/deposit/i
        account = current_user.ssl_account
        order=account.purchase Deposit.create({amount: total_as_cents, payment_method: 'paypal'})
        order.description = "Paypal Deposit"
        order.deposit_mode=true
        order.mark_paid!
        account.funded_account.increment! :cents, total_as_cents
      else
        # current_user.ssl_account.orders << purchase
        # record_order_visit(purchase)
        # credit_affiliate(purchase)
        # clear_cart
      end
      notice = "Thanks! Your purchase is now complete!"
    else
      notice = "Woops. Something went wrong while we were trying to complete the purchase with Paypal. Btw, here's what Paypal said: #{purchase.message}"
    end

    redirect_to order_url(order), :notice => notice
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
