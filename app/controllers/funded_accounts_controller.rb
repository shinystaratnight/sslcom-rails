class FundedAccountsController < ApplicationController
  include OrdersHelper, CertificateOrdersHelper, FundedAccountsHelper
#  resource_controller :singleton
#  ssl_required :allocate_funds, :allocate_funds_for_order, :apply_funds,
#    :deposit_funds
#  belongs_to :user

  before_filter :require_user, :only => [:allocate_funds_for_order,
    :deposit_funds, :allocate_funds, :apply_funds],
    :if=>'current_subdomain==Reseller::SUBDOMAIN'
  filter_access_to :all

  def allocate_funds
    @funded_account = current_user.ssl_account.funded_account
    @funded_account.deduct_order = "false"
    @reseller_initial_deposit = true if initial_reseller_deposit?
  end

  def allocate_funds_for_order
    @funded_account = current_user ? current_user.ssl_account.funded_account :
      FundedAccount.new
    @funded_account.deduct_order = "true"
    if params[:id] == "certificate"
      @certificate_order = current_user.ssl_account.certificate_orders.current
      @funded_account.order_type = "certificate"
    elsif params[:id] == "order"
      certificates_from_cookie
      @funded_account.order_type = "order"
    end
    render :action => "allocate_funds"
  end

  def deposit_funds
    @reseller_initial_deposit = true if initial_reseller_deposit?
    @funded_account, @billing_profile = 
      FundedAccount.new(params[:funded_account]),
      BillingProfile.new(params[:billing_profile])
    if @funded_account.order_type=='certificate'
      @certificate_order = current_user.ssl_account.certificate_orders.current
    elsif @funded_account.order_type=='order'
      setup_certificate_orders
    end
    if params["prev.x".intern]
      if current_user.ssl_account.has_role?('new_reseller')
        current_user.ssl_account.reseller.back!
        redirect_to new_account_reseller_url and return
      elsif @certificate_order
        return go_back_to_buy_certificate
      elsif @certificate_orders
        redirect_to show_cart_orders_url and return
      end
    end
    account = current_user.ssl_account
    @funded_account.ssl_account = @billing_profile.ssl_account = account
    @funded_account.funding_source = FundedAccount::NEW_CREDIT_CARD if
      @funded_account.funding_source.blank?
    if @funded_account.valid?
      @account_total = account.funded_account
      #if not deducting order, then it's a straight deposit since we don't deduct anything
      @order ||= (@funded_account.deduct_order?)? current_order :
        Order.new(:cents => 0, :deposit_mode => true)
      @account_total.cents += @funded_account.amount.cents - @order.cents
      @funded_account.errors.add(:amount, "being loaded is not sufficient") if @account_total.cents <= 0
      @funded_account.errors.add(:amount,
        "minimum deposit load amount is #{Money.new(Settings.minimum_deposit_amount.to_i*100).format}" ) unless
          !@funded_account.amount.nil? && @funded_account.amount.to_s.to_f >
            Settings.minimum_deposit_amount
    end
    if(@funded_account.funding_source!=FundedAccount::NEW_CREDIT_CARD)
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
    @credit_card = ActiveMerchant::Billing::CreditCard.new({
      :first_name => @profile.first_name,
      :last_name  => @profile.last_name,
      :number     => @profile.card_number,
      :month      => @profile.expiration_month,
      :year       => @profile.expiration_year,
      :verification_value => @profile.security_code
    })
    @credit_card.type = 'bogus' if defined?(::GATEWAY_TEST_CODE)
    options = {
      :billing_address => Address.new({
        :name     => @profile.full_name,
        :street1 => @profile.address_1,
        :street2 => @profile.address_2,
        :locality     => @profile.city,
        :region    => @profile.state,
        :country  => @profile.country,
        :postal_code     => @profile.postal_code,
        :phone    => @profile.phone
      }),
      :description => "Deposit"
    }
    if ActiveMerchant::Billing::Base.mode == :test ? true : @credit_card.valid?
      if defined?(::GATEWAY_TEST_CODE)
        @deposit.amount= ::GATEWAY_TEST_CODE
      else
        @deposit.amount= @funded_account.amount
      end
      @deposit.description = "Deposit"
      if initial_reseller_deposit?
        #get this before transaction so user cannot change the cookie, thus 
        #resulting in mismatched item purchased
        immutable_cart_item = ResellerTier.find_by_label(current_order.
            line_items.first.sellable.label)
      end
      @gateway_response = @deposit.purchase(@credit_card, options)
      if @gateway_response.success?
        flash.now[:notice] = @gateway_response.message
        save_billing_profile if
          (@funded_account.funding_source == "new credit card")
        @deposit.billing_profile = @profile
        if apply_order
          @order.deducted_from = @deposit
          current_user.ssl_account.orders << @order
          @order.save
        end
        @account_total.save
        dep.save
        @deposit.save
        if initial_reseller_deposit?
          account.reseller.completed!
          account.reseller.reseller_tier = immutable_cart_item
          account.remove_role! 'new_reseller'
          account.add_role! 'reseller'
        end
        OrderNotifier.deliver_deposit_completed account, @deposit
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
        flash.now[:error] = @gateway_response.message
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
    parse_certificate_orders
    @account_total = @funded_account = current_user.ssl_account.funded_account
    @funded_account.cents -= @order.cents unless @funded_account.blank?
    respond_to do |format|
      if @funded_account.cents >= 0 and @order.line_items.size > 0
        @funded_account.deduct_order = true
        if @order.cents > 0
          @order.save
        end
        @funded_account.save
        flash.now[:notice] = "The transaction was successful."
        if @certificate_order
          @certificate_order.pay! true
          return redirect_to edit_certificate_order_path(@certificate_order)
        elsif @certificate_orders
          current_user.ssl_account.orders << @order
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
        elsif @funded_account.cents <= 0
          flash.now[:error] = "There is insufficient funds in your SSL account"
        end
        format.html { render :action => "confirm_funds" }
      end
    end
  end

  def create_free_ssl
    parse_certificate_orders
    respond_to do |format|
      if @order.cents == 0 and @order.line_items.size > 0
        @order.save
        flash.now[:notice] = "The transaction was successful."
        if @certificate_order
          @certificate_order.pay! true
          return redirect_to edit_certificate_order_path(@certificate_order)
        elsif @certificate_orders
          current_user.ssl_account.orders << @order
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
      @certificate_order = current_user.ssl_account.certificate_orders.current
      check_for_current_certificate_order
    end
  end

  private

  def object
    @object = current_user.ssl_account.funded_account ||= FundedAccount.new(:amount => 0)
  end

  def go_back_to_buy_certificate
    #need to create new objects and delete the existing ones
    @certificate_order = current_user.ssl_account.
      certificate_orders.detect(&:new?)
    @certificate = @certificate_order.certificate
    @certificate_content = @certificate_order.certificate_content.clone
    @certificate_order = current_user.ssl_account.
      certificate_orders.detect(&:new?).clone
    @certificate_order.duration = @certificate.duration_index(@certificate_content.duration)
    @certificate_order.has_csr = true
    render(:template => "/certificates/buy", :layout=>"application")
  end

  def setup_certificate_orders
    #will create @certificate_orders below
    certificates_from_cookie
    @order = Order.new(:amount=>(current_order.amount.to_s.to_i or 0))
    build_certificate_contents(@certificate_orders, @order)
  end

  def save_certificate_orders
    current_user.ssl_account.orders << @order
    OrderNotifier.deliver_certificate_order_prepaid @current_user.ssl_account, @order
    @order.line_items.each do |cert|
      current_user.ssl_account.certificate_orders << cert.sellable
      cert.sellable.pay! true
    end
  end

  def parse_certificate_orders
    if params[:certificate_order]
      @certificate_order = current_user.ssl_account.certificate_orders.current
      unless params["prev.x".intern].nil?
        return go_back_to_buy_certificate
      end
      @order = current_order
    elsif params[:certificate_orders]
      unless params["prev.x".intern].nil?
        redirect_to show_cart_orders_url and return
      end
      setup_certificate_orders
    end
  end
end
