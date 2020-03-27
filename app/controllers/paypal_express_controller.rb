class PaypalExpressController < ApplicationController
  before_action :assigns_gateway, :setup_orders
  before_action :find_ssl_account, only: [:make_deposit, :purchase]
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
    set_order_type
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
          order_w_discount = discount.any? ? (@order.cents - discount.first[:amount].abs) : @order.cents
          if @ssl_account.funded_account.cents >= order_w_discount
            funded_account_credit(purchase_params)
            @ssl_account.funded_account.decrement! :cents, (order_w_discount - @funded_deduct_amt)
            @ssl_account.orders << @order
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
            notice = "Uh oh, not enough funds to complete the purchase. Please deposit #{Money.new(((@ssl_account.funded_account.cents - @order.cents)*0.01))}"
          end
        end
      else
        @auth_code = "#paidviapaypal#{purchase.authorization}"
        if @domains_adjustment
          @certificate_order = @ssl_account.cached_certificate_orders.find_by(ref: params[:co_ref])
          @certificate_content = @ssl_account.certificate_contents.find_by(ref: params[:cc_ref])
          domains_adjustment_order(purchase_params)
          funded_account_credit(purchase_params)
          @order.notes += " #{@auth_code}"
          @certificate_order.add_reproces_order @order
        elsif params[:smime_client_order]
          smime_client_enrollment_order(purchase_params)
          funded_account_credit(purchase_params)
        elsif params[:monthly_invoice]
          @invoice = Invoice.find_by(reference_number: params[:invoice_ref])
          setup_monthly_invoice_order(purchase_params)
          funded_account_credit(purchase_params)
          @order.notes += " #{@auth_code}"
        else
          setup_orders
          @order.notes = @auth_code
        end
        @order.lock!
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
    
    if @domains_adjustment
      flash[:notice] = "Succesfully paid for UCC domains adjustment order."
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)
    elsif params[:smime_client_order]
      @order.update(state: 'paid') if @order.persisted? && @order.state == 'invoiced'
      flash[:notice] = "Succesfully paid S/MIME or Client Enrollment."
      redirect_to order_path(@ssl_slug, @order)
    elsif params[:monthly_invoice]
      flash[:notice] = "Succesfully paid for invoice #{@invoice.reference_number}."
      redirect_to invoice_path(@ssl_slug, @invoice.reference_number)
    else
      redirect_to orders_url, notice: notice
    end
  end

  private
  
  def smime_client_enrollment_order(purchase_params)
    @emails = params[:emails]
    @emails = smime_client_parse_emails(@emails)
    product = params[:certificate]
    @certificate = Certificate.find_by(product: product)
    certificate_orders = smime_client_enrollment_items
    
    @order = SmimeClientEnrollmentOrder.new(
      state: 'new',
      approval: 'approved',
      invoice_description: smime_client_enrollment_notes(certificate_orders.count),
      description: Order::S_OR_C_ENROLLMENT,
      billable_id: certificate_orders.first.ssl_account.try(:id),
      billable_type: 'SslAccount',
      notes: @auth_code
    )
    @order.add_certificate_orders(certificate_orders)
    if @order.save
      smime_client_enrollment_co_paid
      smime_client_enrollment_registrants
      smime_client_enrollment_validate
    end
  end
  
  def domains_adjustment_order(purchase_params)
    order_params = { 
      amount:               Money.new(purchase_params[:subtotal]),
      cents:                purchase_params[:subtotal],
      description:          Order::DOMAINS_ADJUSTMENT,
      state:                'pending',
      approval:             'approved',
      notes:                get_order_notes,
      invoice_description:  params[:order_description],
      wildcard_amount:      params[:wildcard_amount],
      non_wildcard_amount:  params[:nonwildcard_amount]
    }
    @order = @reprocess_ucc ? ReprocessCertificateOrder.new(order_params) : Order.new(order_params)
    @order.billable = @ssl_account
    ucc_update_domain_counts
    @order.save
  end
  
  def setup_monthly_invoice_order(purchase_params)
    @order = Order.new(
      amount:        Money.new(purchase_params[:subtotal]),
      cents:         purchase_params[:subtotal],
      description:   @ssl_account.get_invoice_pmt_description,
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
  
  def set_order_type
    @reprocess_ucc   = params[:reprocess_ucc]
    @renew_ucc       = params[:renew_ucc]
    @ucc_csr_submit  = params[:ucc_csr_submit]
    @payable_invoice = params[:monthly_invoice]
    @domains_adjustment = @reprocess_ucc || @renew_ucc || @ucc_csr_submit
  end
  
  def get_funded_account_amt(purchase_params)
    @funded_exists = purchase_params[:items].find {|i| i[:name]=='Funded Account'}
    @funded_deduct_amt = @funded_exists ? @funded_exists[:amount].abs : 0
  end

  def funded_account_credit(purchase_params)
    get_funded_account_amt(purchase_params)
    names = [
      'Monthly Invoice Pmt',
      'Reprocess UCC Cert',
      'Renew UCC Cert',
      'UCC Cert Adjustment',
      'Deposit',
      'S/MIME Client Enroll'
    ]
    order_amount = purchase_params[:items].find {|i| names.include?(i[:name])}[:amount]
    if @funded_exists && @funded_deduct_amt > 0
      withdraw_funded_account(@funded_deduct_amt, order_amount)
    end
  end
end
