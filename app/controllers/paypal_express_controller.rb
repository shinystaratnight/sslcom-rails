class PaypalExpressController < ApplicationController
  before_filter :assigns_gateway, :setup_orders
  before_filter :find_ssl_account, only: [:make_deposit, :purchase]
  include ActiveMerchant::Billing
  include ApplicationHelper, OrdersHelper, PaypalExpressHelper, FundedAccountsHelper

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
    total_as_cents, setup_purchase_params = get_setup_purchase_params(item_to_buy, request, params)
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
    if ::Rails.env.test?
      UserSession.create(User.first, true)
      current_user = Authorization.current_user = User.first
      @ssl_account = current_user.ssl_account
    end
    total_as_cents, purchase_params = get_purchase_params @gateway.details_for(params[:token]), request, params
    purchase = @gateway.purchase total_as_cents, purchase_params

    if purchase.success?
      discount = purchase_params[:items].select {|i| i[:name]=='Discount'}
      params[:discount_code] = discount.first[:Number] if discount.any?

      # you might want to destroy your cart here if you have a shopping cart
      if purchase_params[:items][0][:name]=~/(deposit|reseller)/i
        @deposit=@ssl_account.purchase Deposit.create({amount: total_as_cents, payment_method: 'paypal'})
        @deposit.description = "Paypal Deposit"
        @deposit.notes = "#paidviapaypal#{purchase.authorization}"
        @deposit.deposit_mode=true
        @deposit.mark_paid!
        @ssl_account.funded_account.increment! :cents, total_as_cents
        unless params[:deduct_order]=~/false/i
          if initial_reseller_deposit?
            @order = current_order
            #get this before transaction so user cannot change the cookie, thus
            #resulting in mismatched item purchased
            immutable_cart_item = ResellerTier.find_by_label(@order.
                line_items.first.sellable.label)
          else
            setup_orders
          end
          funded_account_credit(purchase_params)
          order_w_discount = discount.any? ? (@order.cents - discount.first[:amount].abs) : @order.cents
          if @ssl_account.funded_account.cents >= order_w_discount
            @ssl_account.orders << @order
            @ssl_account.funded_account.decrement! :cents, order_w_discount
            @order.finalize_sale(params: params, deducted_from: @deposit,
                                 visitor_token: @visitor_token, cookies: cookies)
            if initial_reseller_deposit?
              @ssl_account.reseller.finish_signup immutable_cart_item
            end
            if @funded
              @funded.update(notes: "Partial payment for order ##{@order.reference_number} ($#{@order.amount.to_s}).")
            end
            notice = "Your purchase is now complete!"
            clear_cart
          else
            notice = "Uh oh, not enough funds to complete the purchase. Please deposit #{((@ssl_account.funded_account.cents - @order.cents)*0.01).to_money}"
          end
        end
      else
        setup_orders
        @ssl_account.orders << @order
        @order.notes = "#paidviapaypal#{purchase.authorization}"
        @order.finalize_sale(params: params, deducted_from: @deposit,
                             visitor_token: @visitor_token, cookies: cookies)
        notice = "Your purchase is now complete!"
        clear_cart
      end
    else
      notice = "Woops. Something went wrong while we were trying to complete the purchase with Paypal. Btw, here's what Paypal said: #{purchase.message}"
    end
    redirect_to orders_url, :notice => notice
  end

  private
  def assigns_gateway
    s = ::Rails.application.secrets
    @gateway ||= PaypalExpressGateway.new(
      login:     s.paypal_username,
      password:  s.paypal_password,
      signature: s.paypal_signature
    )
  end

  def funded_account_credit(purchase_params)
    funded_exists = purchase_params[:items].find {|i| i[:name]=='Funded Account'}
    funded_amt    = funded_exists[:amount].abs if funded_exists
    if funded_exists && funded_amt > 0
      fund = Deposit.create(
        amount:         funded_amt,
        full_name:      "Team #{@ssl_account.get_team_name} funded account",
        credit_card:    'N/A',
        last_digits:    'N/A',
        payment_method: 'Funded Account'
      )
      @funded             = @ssl_account.purchase fund
      @funded.description = 'Funded Account Withdrawal'
      @funded.save
      @funded.mark_paid!
    end
  end
end
