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
    paypal_details = @gateway.details_for(params[:token])
    total_as_cents, purchase_params = get_purchase_params paypal_details, request, params
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
        auth_code = "#paidviapaypal#{purchase.authorization}"
        
        if params[:reprocess_ucc]
          setup_reprocess_ucc_order(purchase_params)
          funded_account_credit(purchase_params)
          @order.notes += " #{auth_code}"
          @certificate_order = @ssl_account.certificate_orders.find_by(ref: params[:co_ref])
          @certificate_order.add_reproces_order @order
        elsif params[:monthly_invoice]
          @invoice = MonthlyInvoice.find_by(reference_number: params[:invoice_ref])
          setup_monthly_invoice_order(purchase_params)
          funded_account_credit(purchase_params)
          @order.notes += " #{auth_code}"
        else
          setup_orders
          @order.notes = auth_code
        end
        
        @ssl_account.orders << @order
        @order.finalize_sale(
          params: params,
          deducted_from: @deposit,
          visitor_token: @visitor_token,
          cookies: cookies
        )
        notice = "Your purchase is now complete!"
        billed_to_address(paypal_details) unless params[:monthly_invoice]
        clear_cart
      end
    else
      notice = "Woops. Something went wrong while we were trying to complete the purchase with Paypal. Btw, here's what Paypal said: #{purchase.message}"
    end
    
    if params[:reprocess_ucc]
      flash[:notice] = "Succesfully paid for UCC reprocess order."
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)
    elsif params[:monthly_invoice]
      flash[:notice] = "Succesfully paid for invoice #{@invoice.reference_number}."
      redirect_to invoice_path(@ssl_slug, @invoice.reference_number)
    else
      redirect_to orders_url, notice: notice
    end
  end

  private
  
  def setup_reprocess_ucc_order(purchase_params)
    @order = ReprocessCertificateOrder.new(
      amount:        Money.new(purchase_params[:subtotal]),
      cents:         purchase_params[:subtotal],
      description:   Order::DOMAINS_ADJUSTMENT,
      state:         'pending',
      approval:      'approved',
      notes:         "Reprocess UCC (certificate order: #{params[:co_ref]}, certificate content: #{params[:cc_ref]})."
    )
    @order.billable = @ssl_account
    @order.save
  end
  
  def setup_monthly_invoice_order(purchase_params)
    @order = Order.new(
      amount:        Money.new(purchase_params[:subtotal]),
      cents:         purchase_params[:subtotal],
      description:   Order::INVOICE_PAYMENT,
      state:         'pending',
      approval:      'approved',
      notes:         order_invoice_notes
    )
    @order.billable = @ssl_account
    @order.save
    @invoice.update(order_id: @order.id, status: 'paid') if @order.persisted?
  end
  
  def billed_to_address(paypal_details)
    attrs = paypal_details.params['PayerInfo']['Address']
    if @order && @order.persisted?
      Invoice.create(
        order_id:    @order.id, 
        first_name:  attrs['Name'].split.first,
        last_name:   attrs['Name'].split.last,
        address_1:   attrs['Street1'],
        address_2:   attrs['Street2'],
        city:        attrs['CityName'],
        state:       attrs['StateOrProvince'],
        postal_code: attrs['PostalCode'],
        country:     attrs['Country'],
      )
    end
  end
  
  def assigns_gateway
    s = ::Rails.application.secrets
    @gateway ||= PaypalExpressGateway.new(
      login:     s.paypal_username,
      password:  s.paypal_password,
      signature: s.paypal_signature
    )
  end

  def funded_account_credit(purchase_params)
    special_order = params[:reprocess_ucc] || params[:monthly_invoice]
    funded_exists = purchase_params[:items].find {|i| i[:name]=='Funded Account'}
    funded_amt    = funded_exists ? funded_exists[:amount].abs : 0
    amount_str    = if special_order
      Money.new(@order.cents + funded_amt).format
    else
      @order.amount.format
    end

    if funded_exists && funded_amt > 0
      fund = Deposit.create(
        amount:         funded_amt,
        full_name:      "Team #{@ssl_account.get_team_name} funded account",
        credit_card:    'N/A',
        last_digits:    'N/A',
        payment_method: 'Funded Account'
      )
      @funded = @ssl_account.purchase fund
      @funded.description = 'Funded Account Withdrawal'
      @funded.notes = "Partial payment for order ##{@order.reference_number} (#{amount_str})"
      @funded.notes << ' for UCC certificate reprocess.' if params[:reprocess_ucc]
      @funded.notes << " for monthly invoice ##{@invoice.reference_number}." if params[:monthly_invoice]
      @funded.save
      @funded.mark_paid!
      @ssl_account.funded_account.decrement!(:cents, funded_amt) if special_order
    end
  end
end
