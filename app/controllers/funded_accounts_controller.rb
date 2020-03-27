class FundedAccountsController < ApplicationController
  include OrdersHelper, CertificateOrdersHelper, FundedAccountsHelper
  before_filter :go_prev, :parse_certificate_orders, only: [:apply_funds, :create_free_ssl]
#  resource_controller :singleton
#  ssl_required :allocate_funds, :allocate_funds_for_order, :apply_funds,
#    :deposit_funds
#  belongs_to :user
  before_filter :require_user, :only => [:allocate_funds_for_order,
    :deposit_funds, :allocate_funds, :apply_funds, :confirm_funds]
  before_filter :find_ssl_account
  skip_before_filter :finish_reseller_signup
  filter_access_to :all

  def allocate_funds
    @funded_account = @ssl_account.funded_account
    @funded_account.deduct_order = "false"
    @reseller_initial_deposit = true if initial_reseller_deposit?
  end

  # apply funds from funded_account to purchase the order
  def allocate_funds_for_order
    @funded_account = current_user ? @ssl_account.funded_account : FundedAccount.new
    @funded_account.deduct_order = "true"
    if params[:id] == "certificate"
      @certificate_order = @ssl_account.certificate_orders.current
      @funded_account.order_type = "certificate"
    elsif params[:id] == "order"
      certificates_from_cookie
      @funded_account.order_type = "order"
    end
    render :action => "allocate_funds"
  end

  # Deposit funds into the funded_account
  def deposit_funds
    too_many_declines = delay_transaction?
    @reseller_initial_deposit = true if initial_reseller_deposit?
    @funded_account, @billing_profile = 
      FundedAccount.new(params[:funded_account]),
      BillingProfile.new(params[:billing_profile])
    # After discount, check if sufficient funds in funded account for final amount 
    if @funded_account.deduct_order? && params[:discount_amount] && sufficient_funds?(params)
      new_params = params.select{|k,v| %w{funded_account discount_code discount_amount}.include?(k)}
      redirect_to apply_funds_path(new_params.deep_symbolize_keys) and return
    end
    if @funded_account.order_type=='certificate'
      @certificate_order = @ssl_account.certificate_orders.current
    elsif @funded_account.order_type=='order'
      setup_orders
    end
    if params["prev.x".intern]
      if @ssl_account.has_role?('new_reseller')
        @ssl_account.reseller.back!
        redirect_to new_account_reseller_url and return
      elsif @certificate_order
        return go_back_to_buy_certificate
      elsif @certificate_orders
        redirect_to show_cart_orders_url and return
      end
    end
    account = @ssl_account
    @funded_account.ssl_account = @billing_profile.ssl_account = account
    @funded_account.funding_source = FundedAccount::NEW_CREDIT_CARD if @funded_account.funding_source.blank?
    if @funded_account.valid?
      @account_total = account.funded_account(true)
      @funded_original = @account_total.cents
      #if not deducting order, then it's a straight deposit since we don't deduct anything
      @order ||= (@funded_account.deduct_order?)? current_order :
        Order.new(:cents => 0, :deposit_mode => true)
      if @funded_account.deduct_order?
        deduct_order_amounts(params)
      else
        @account_total.cents += @funded_account.amount.cents - @order.cents
      end
      unless @funded_account.deduct_order?
        # do this before we attempt to deduct funds
        @funded_account.errors.add(:amount, "being loaded is not sufficient") if
            @account_total.cents <= 0 #should redirect to load funds page prepopulated with the amount difference
        if @funded_account.amount && (@funded_account.amount.to_s.to_f < Settings.minimum_deposit_amount)
          @funded_account.errors.add(:amount,
            "minimum deposit load amount is #{Money.new(Settings.minimum_deposit_amount.to_i*100).format}"
          )
        end
      end
    end
    if(@funded_account.funding_source!=FundedAccount::NEW_CREDIT_CARD) #existing credit card
      @profile = BillingProfile.find(@funded_account.funding_source)
    else
      @profile = @billing_profile
      @billing_profile.valid?
    end
    render :action => "allocate_funds", :id => account and
      return unless(@funded_account.errors.empty? and
        (@funded_account.funding_source==FundedAccount::NEW_CREDIT_CARD)?
        @billing_profile.errors.empty? : true)
    dep = Deposit.new({
      :amount => @funded_account.amount.cents,
      :full_name => @profile.full_name,
      :credit_card => @profile.credit_card,
      :last_digits => @profile.last_digits,
      :payment_method => 'credit card'})
    @deposit = account.purchase dep
    if @funded_account.deduct_order? && @funded_withdrawal > 0
      fund = Deposit.new(
        amount:         @funded_withdrawal,
        full_name:      "Team #{@ssl_account.get_team_name} funded account",
        credit_card:    'N/A',
        last_digits:    'N/A',
        payment_method: 'Funded Account'
      )
      @funded = account.purchase fund
    end
    @credit_card = @profile.build_credit_card
    if ActiveMerchant::Billing::Base.mode == :test ? true : @credit_card.valid?
      @deposit.amount = @funded_account.amount
      @deposit.description = "Deposit"
      @funded.description = 'Funded Account Withdrawal' if @funded
      if initial_reseller_deposit?
        #get this before transaction so user cannot change the cookie, thus 
        #resulting in mismatched item purchased
        immutable_cart_item = ResellerTier.find_by_label(current_order.
            line_items.first.sellable.label)
      end
      unless too_many_declines
        options = @profile.build_info("Deposit").merge(owner_email: @ssl_account.get_account_owner.email)
        @gateway_response = @deposit.purchase(@credit_card, options)
      end
      if @gateway_response && @gateway_response.success?
        @deposit.mark_paid!
        flash.now[:notice] = @gateway_response.message
        save_billing_profile if
          (@funded_account.funding_source == "new credit card")
        @deposit.billing_profile = @profile
        if apply_order
          @order.deducted_from = @deposit
          @ssl_account.orders << @order
          apply_discounts(@order) #this needs to happen before the transaction but after the final incarnation of the order
          @order.commit_discounts
          record_order_visit(@order)
          @order.mark_paid!
          @order.credit_affiliate(cookies)
        end
        @account_total.save
        dep.save
        @deposit.save
        if @funded
          @funded.notes = "Partial payment for order ##{@order.reference_number} ($#{@order.amount.to_s})."
          fund.save
          @funded.save
          @funded.mark_paid!
        end
        if initial_reseller_deposit?
          account.reseller.finish_signup immutable_cart_item
        end
        log_deposit
        OrderNotifier.deposit_completed(account, @deposit).deliver if Settings.invoice_notify
        if @certificate_order
          @certificate_order.pay! @gateway_response.success?
          route ||= "edit"
        elsif @certificate_orders
          clear_cart
          flash[:notice] = "Order successfully placed. %s"
          flash[:notice_item] = "Click here to finish processing your
            ssl.com certificates.", credits_certificate_orders_path
          route ||= "order"
        end
        route ||= "success"
      else
        log_declined_transaction(@gateway_response, @credit_card.number.last(4)) if @gateway_response
        @deposit.destroy
        if @funded
          @funded.destroy
          @account_total.cents = @funded_original # put original amount back on the funded account
        end
        if @funded_account.valid? && !@funded_account.deduct_order?
          @ssl_account.funded_account.update(cents: @funded_original)
        end
        flash[:error] = @gateway_response.message if @gateway_response
        flash[:error] = 'Too many failed attempts, please wait 1 minute to try again!' if too_many_declines
      end
      route ||= "allocate"
    end
    route ||= "allocate"
    respond_to do |format|
      case route
      when /allocate/
        format.html { render :action => "allocate_funds" }
      when /success/
        format.html { render :action => "success" }
      when /order/
        format.html { redirect_to @order }
      when /edit/
        redirect_to edit_certificate_order_path(@certificate_order) and return
      end
    end
    rescue Payment::AuthorizationError => error
      flash.now[:error] = error.message
      render :action => 'allocate_funds'
  end

  def apply_funds
    @account_total = @funded_account = @ssl_account.funded_account
    apply_discounts(@order) # this needs to happen before the transaction but after the final incarnation of the order
    @funded_account.cents -= @order.final_amount.cents unless @funded_account.blank?
    respond_to do |format|
      if @funded_account.cents >= 0 and @order.line_items.size > 0
        @funded_account.deduct_order = true
        if @order.final_amount.cents > 0
          record_order_visit(@order)
          @order.mark_paid!
        end
        @funded_account.save
        flash.now[:notice] = 'The transaction was successful.'
        if @certificate_order
          @certificate_order.pay! true
          return redirect_to edit_certificate_order_path(@certificate_order)
        elsif @certificate_orders
          @ssl_account.orders << @order
          clear_cart
          flash[:notice] = 'Order successfully placed. %s'
          flash[:notice_item] = 'Click here to finish processing your ssl.com certificates.', credits_certificate_orders_path
          format.html { redirect_to order_path(ssl_slug: @ssl_account.ssl_slug, id: @order.id) }
        end
        format.html { render :action => "success" }
      else
        if @order.line_items.size == 0
          flash.now[:error] = "Cart is currently empty"
        elsif @funded_account.cents <= 0
          flash.now[:error] = "There is insufficient funds in your SSL account"
        end
        format.html { render :action => "confirm_funds" }
      end
    end
  end

  def create_free_ssl
    respond_to do |format|
      if @order.cents == 0 and @order.line_items.size > 0
        record_order_visit(@order)
        @order.give_away!
        if @certificate_order
          @certificate_order.pay! true
          return redirect_to edit_certificate_order_path(@certificate_order)
        elsif @certificate_orders
          @ssl_account.orders << @order
          clear_cart
          flash[:notice] = "Order successfully placed. %s"
          flash[:notice_item] = "Click here to finish processing your
            ssl.com certificates.", credits_certificate_orders_path
          format.html { redirect_to @order }
        end
        format.html { render :action => "success" }
      else
        if @order.line_items.size == 0
          flash.now[:error] = "Cart is currently empty"
        elsif @order.cents > 0
          flash.now[:error] = "Cannot process non-free products"
        end
        if @certificate_order
          return go_back_to_buy_certificate
        else
          format.html { redirect_to show_cart_orders_url }
        end
      end
    end
  end

  def confirm_funds
    if params[:id]=='order'
      certificates_from_cookie
    else
      @certificate_order = @ssl_account.certificate_orders.current
      check_for_current_certificate_order
    end
  end

  private

  def object
    @object = @ssl_account.funded_account ||= FundedAccount.new(:amount => 0)
  end

  def save_certificate_orders
    @ssl_account.orders << @order
    OrderNotifier.certificate_order_prepaid(@ssl_account, @order).deliver
    @order.line_items.each do |cert|
      @ssl_account.cached_certificate_orders << cert.sellable
      cert.sellable.pay! true
    end
  end

  def deduct_order_amounts(params)
    discount           = params[:discount_amount]
    discount           = (discount && discount.to_f > 0) ? to_cents(discount) : 0
    price_w_discount   = @funded_account.amount.cents - discount
    @funded_original   = @account_total.cents # existing amount on funded account
    @funded_withdrawal = @account_total.cents # credited toward purchase amount from funded account
    # target amount user has chosen to deposit to go towards order amount
    # and/or additional deposit to funded account if in surplus
    @funded_target    = Money.new(@funded_account.target_amount.to_f * 100)
    
    # determine whether to tap into existing funds in the funded account
    @funded_diff      = @funded_target.cents - (price_w_discount - @funded_withdrawal)
    if (@funded_diff >= 0)  # deposit will cover cost of purchase and/or surplus for funded account
      @account_total.cents  += @funded_diff if (@funded_diff > 0)
    end
    @funded_account.amount   = @funded_target
    @account_total.cents    -= @funded_withdrawal
  end
  
  def log_deposit
    unless @funded_account.deduct_order?
      gateway = BillingProfile.gateway_stripe? ? 'Stripe' : 'Authorize.net'
      notes   = [
        "User #{current_user.login} has made a deposit",
        "(order id: #{@gateway_response.order_id}) of $#{@funded_account.amount}",
        "for team #{@ssl_account.get_team_name} through #{gateway} merchant."
      ]
      SystemAudit.create(
        owner:  current_user,
        target: @ssl_account.funded_account,
        action: 'Made a deposit to funded account (FundedAccountsController#deposit_funds).',
        notes:  notes.join(' ')
      )
    end
  end
  
  def sufficient_funds?(params)
    funded_amt   = @ssl_account.funded_account.amount.cents
    order_amt    = to_cents(params[:funded_account][:amount])
    discount     = params[:discount_amount]
    discount_amt = (discount && discount.to_f > 0) ? to_cents(discount) : 0
    (funded_amt - (order_amt - discount_amt)) >= 0
  end
  
  def to_cents(amount)
    Money.new(amount.to_f * 100).cents
  end
end
