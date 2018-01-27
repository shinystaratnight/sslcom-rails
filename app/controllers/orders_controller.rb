class OrdersController < ApplicationController
  require 'cgi'
  layout false, only: :invoice
  include OrdersHelper
  #resource_controller
  helper_method :cart_items_from_model_and_id
  before_filter :finish_reseller_signup, :only => [:new], if: "current_user"
  before_filter :find_order, :only => [:show, :invoice, :update_invoice, :refund, :refund_merchant, :change_state]
  before_filter :find_user, :only => [:user_orders]
  before_filter :set_prev_flag, only: [:create, :create_free_ssl, :create_multi_free_ssl]
  before_filter :prep_certificate_orders_instances, only: [:create, :create_free_ssl]
  before_filter :go_prev, :parse_certificate_orders, only: [:create_multi_free_ssl]
  before_filter :set_row_page, only: [:index, :search, :filter_by_state, :visitor_trackings]


#  before_filter :sync_aid_li_and_cart, :only=>[:create],
#    :if=>Settings.sync_aid_li_and_cart
  filter_access_to :all
  filter_access_to :visitor_trackings, :filter_by_state, require: [:index]
  filter_access_to :show, :update_invoice, attribute_check: true

  def show_cart
    @cart = ShoppingCart.find_by_guid(params[:id]) if params[:id]
    if @cart # manually overwrite owned shopping_cart in favor or url specified
      cookies[:cart] = {:value=>(@cart.content.blank? ? @cart.content : CGI.unescape(@cart.content)), :path => "/",
                        :expires => Settings.cart_cookie_days.to_i.days.from_now}
    else
      cart = cookies[:cart]
      guid = cookies[:cart_guid]
      db_cart = ShoppingCart.find_by_guid(guid)
      if current_user
        if current_user.shopping_cart
          guid=current_user.shopping_cart.guid
          cookies[:cart_guid] = {:value=>guid, :path => "/",
                                 :expires => Settings.cart_cookie_days.to_i.days.from_now} # reset guid
          current_user.shopping_cart.update_attribute :content, cart
        # elsif guid && db_cart
        #     db_cart.update_attributes content: cart, user_id: current_user.id
        else # each user should 'own' a db_cart
          guid=UUIDTools::UUID.random_create.to_s
          cookies[:cart_guid] = {:value=>guid, :path => "/", :expires => Settings.cart_cookie_days.to_i.days.from_now}
          current_user.create_shopping_cart(guid: guid, content: cart)
        end
      elsif guid && db_cart #assume user is not logged in
        db_cart.update_attribute :content, cart
      else
        guid=UUIDTools::UUID.random_create.to_s
        cookies[:cart_guid] = {:value=>guid, :path => "/", :expires => Settings.cart_cookie_days.to_i.days.from_now}
        ShoppingCart.create(guid: guid, content: cart)
      end
      redirect_to show_cart_orders_path(id: guid)
    end
    setup_orders
  end  

  def add
    add_to_cart @line_item = ActiveRecord::Base.find_from_model_and_id(param)
    session[:cart_items].uniq!

    respond_to do |format|
      format.js { render :action => "cart_quantity.js.erb", :layout => false }
    end
  end

  def new
    if params[:certificate_order]
      @certificate = Certificate.for_sale.find_by_product(params[:certificate][:product])
      unless params["prev.x".intern].nil?
        redirect_to buy_certificate_url(@certificate) and return
      end
      render(:template => "/certificates/buy",
        :layout=>"application") and return unless certificate_order_steps
    else
      certificates_from_cookie
    end
    if current_user
      if @certificate_orders && is_order_free?
        create_multi_free_ssl
      elsif current_user.ssl_account.funded_account.cents > 0
        redirect_to(is_current_order_affordable? ? confirm_funds_url(:order) :
                        allocate_funds_for_order_path(id: :order)) and return
      end
    end
  end

  def remove
    unless session[:cart_items].nil?
      @line_item = ActiveRecord::Base.find_from_model_and_id(param)
      session[:cart_items].delete @line_item.model_and_id
    end
    
    respond_to do |format|
      format.js { render :action => "remove_item.js.erb", :layout => false }
    end
  end

  def empty_cart
    @item_classes = session[:cart_items].collect{|cart_item| cart_item.split(/_(?=\d+$)/)[0]}.uniq!
    session[:cart_items].clear
    
    respond_to do |format|
      format.js { render :action => "cart_quantity.js.erb", :layout => false }
    end
  end

  def invoice
    @orders  = [@order]
    invoices = !params[:start_date].blank? && !params[:end_date].blank?

    if invoices
      start   = DateTime.parse(params[:start_date])
      finish  = DateTime.parse(params[:end_date])
      @orders = (current_user.is_system_admins? ? @order.billable : current_user.ssl_account).orders.where(
        state: 'paid',
        created_at: start..finish,
        description: 'SSL Certificate Order'
      )
    end
    
    filename = if @orders.any? && @orders.count == 1
      "ssl.com_invoice_ref_#{@orders.first.reference_number}"
    elsif invoices
      "ssl.com_invoices_#{start.strftime('%F')}_#{finish.strftime('%F')}"
    else
      "ssl.com_invoices_#{Date.today.strftime('%F')}"
    end
    
    respond_to do |format|
      if @orders.any?
        format.html { render pdf: filename }
      else
        flash[:error] = if invoices 
          'Zero orders found for this date range!'
        else
          'This order does not exist!'
        end
        format.html { redirect_to :back }
      end
    end
  end
  
  def update_invoice
    found   = Invoice.find_by(order_id: @order.id)
    update  = found ? found : Invoice.new(params[:invoice])
    no_errors = found ? update.update_attributes(params[:invoice]) : update.save

    respond_to do |format|
      if no_errors
        format.json { render json: update, status: :ok }
      else
        format.json { render json: update.errors, status: :unprocessable_entity }
      end
    end
  end

  def lookup_discount
    if current_user and !current_user.is_system_admins?
      @discount=current_user.ssl_account.discounts.find_by_ref(params[:discount_code]) ||
          Discount.viable.general.find_by_ref(params[:discount_code])
    else
      @discount=Discount.viable.general.find_by_ref(params[:discount_code])
    end
  rescue
  end

  def user_orders
    @orders = current_user.orders
  end

  def studio_orders
    @yahoo_grid = "yui-t1"
    @line_items = @studio.line_items
  end

  def affiliate_orders
    @yahoo_grid = "yui-t1"
    @affiliate = Affiliate.find(params[:affiliate_id])
    @line_items = @affiliate.line_items
  end

  def search
    index
  end

  def refund
    @performed="canceled #{'partial ' if params["partial"]}order"
    unless @order.blank?
      unless params["partial"] # full refund
        @target = @order
        if params["return_funds"]
          @order.billable.funded_account.add_cents(@order.make_available_total)
          @performed << " and made #{Money.new(@order.make_available_total).format} available to customer."
        end
        @order.full_refund!
        @order.certificate_orders.each do |co|
          co.revoke!(params["refund_reason"], current_user)
        end
        notify_ca(params["refund_reason"])
      else # partial refunds or cancel line item
        @target = @order.line_items.find {|li|li.sellable.try(:ref)==params["partial"]}
        @target ||= @order.certificate_orders.find { |co| co.ref==params["partial"] }
        refund_partial_amount(params) if params["return_funds"]
        refund_partial_cancel(params) if params["cancel_only"]

        if @target.is_a?(LineItem) && @target.sellable.is_a?(CertificateOrder)
          @target.sellable.revoke!(params["refund_reason"], current_user)
        end
        if @target.is_a?(CertificateOrder)
          @target.revoke!(params["refund_reason"], current_user)
        end
      end
      SystemAudit.create(owner: current_user, target: @target, notes: params["refund_reason"], action: @performed)
    end
    redirect_to order_url(@order)
  end

  def notify_ca(notes)
    @order.line_items.each { |li|
      OrderNotifier.request_comodo_refund("refunds@ssl.com", li.sellable.external_order_number, notes).deliver if (defined? li.sellable.external_order_number)
      OrderNotifier.request_comodo_refund("refunds@comodo.com", li.sellable.external_order_number,
                                          notes).deliver if (defined?(li.sellable.external_order_number) && li.sellable.external_order_number)
      OrderNotifier.request_comodo_refund("refunds@ssl.com", $1, notes).deliver if li.sellable.try(:notes) =~ /DV#(\d+)/
    }
  end
  
  def refund_merchant
    unless @order.blank?
      @refunds = @order.refunds
      if params[:type] == 'create'
        co = CertificateOrder.find(params[:cancel_cert_order].to_i) if params[:cancel_cert_order]
        amount      = Money.new(co ? @order.make_available_line(co, :merchant) : (params[:refund_amount].to_d * 100))
        refund      = @order.refund_merchant(amount.cents, params[:refund_reason], current_user.id)
        last_refund = @order.refunds.last
        if refund && last_refund && last_refund.successful?
          flash[:notice] = "Successfully refunded merchant for amount #{amount.format}."
          if co
            funded = @order.make_available_funded(co)
            co.refund!
            co.revoke!(params["refund_reason"], current_user)
            SystemAudit.create(
              owner:  current_user,
              target: co,
              notes:  params["refund_reason"],
              action: "Cancelled partial order #{co.ref}, merchant refund issued for #{amount.format}."
            )
            if funded > 0
              @order.billable.funded_account.add_cents(funded)
              flash[:notice] << " And made $#{Money.new(funded).format} available to customer."
            end
          end

        else
          flash[:error] = "Refund for #{amount.format} has failed! #{last_refund.message}"
        end
      end
    end
  end

  def change_state
    performed="order changed to #{params[:state]}"
    unless @order.blank?
      @order.send "#{params[:state]}!"
      SystemAudit.create(owner: current_user, target: @order, action: performed)
      notify_ca(params[:state]) if params[:state]=="charge_back"
    end
    redirect_to order_url(@order)
  end

  # GET /orders
  # GET /orders.xml
  def index
    @search = params[:search]
    unpaginated =
      if !@search.blank?
        if current_user.is_system_admins?
          (@ssl_account.try(:orders) ? Order.unscoped{@ssl_account.try(:orders)} : Order.unscoped).where{state << ['payment_declined']}.search(params[:search])
        else
          current_user.ssl_account.orders.not_new.search(params[:search])
        end
      else
        if current_user.is_system_admins?
          (@ssl_account.try(:orders) ? Order.unscoped{@ssl_account.try(:orders)} : Order.unscoped).where{state << ['payment_declined']}.order("created_at desc").not_test
        else
          current_user.ssl_account.orders.not_test
        end
      end.uniq

    stats(unpaginated)

    respond_to do |format|
      format.html { render :action => :index}
      format.xml  { render :xml => @orders }
    end
  end

  def stats(unpaginated)
    @negative = unpaginated.where{state >> ['fully_refunded','charged_back', 'canceled']}.sum(:cents)
    @paid_via_deposit = unpaginated.where{billing_profile_id == nil }.sum(:cents)
    @deposits_amount=unpaginated.joins { line_items.sellable(Deposit) }.sum(:cents)
    @deposits_count=unpaginated.joins { line_items.sellable(Deposit) }.count
    @total_amount=unpaginated.sum(:cents)-@deposits_amount-@negative
    @total_count=unpaginated.count
    @orders=unpaginated.paginate(@p)
  end

  def filter_by_state
    states = [params[:id]]
    unpaginated =
      if current_user.is_admin?
        Order.unscoped{Order.includes(:line_items).where{state >> states}.order("created_at desc")}
      else
        current_user.ssl_account.orders.unscoped{
          current_user.ssl_account.orders.includes(:line_items).where{state >> states}.order(:created_at.desc)}
      end
    stats(unpaginated)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @orders }
    end
  end

  def visitor_trackings
    @search = params[:search]
    p = {:page => params[:page]}

    @orders =
        if !@search.blank?
          Order.search(params[:search]).paginate(p)
        else
          Order.paginate(p)
        end
  end

  # GET /orders/1
  # GET /orders/1.xml
  def show
    @order.receipt=true
    if @order.description =~ /Deposit|Funded Account Withdrawal/i
      @deposit = @order
    elsif @order.line_items.count==1
      @certificate_order = @order.certificate_orders.uniq.last
    else
      certificates=[]
      @certificate_orders = @order.certificate_orders.uniq.map{|co|
        unless certificates.include?(co.certificate)
          certificates<<co.certificate
          co
        end}.compact
    end
    cookies[:acct] = {:value=>current_user.ssl_account.acct_number, :path => "/", :expires => Settings.
        cart_cookie_days.to_i.days.from_now}
    respond_to do |format|
      if @order.line_items.count==1
        format.html { render "/funded_accounts/success", :layout=>'application'}
      else
        format.html { render :action=>:show}
      end
      format.xml  { render :xml => @order }
    end
  end

  def create
    @order = Order.new(params[:order])
    @profile = @billing_profile = BillingProfile.new(params[:billing_profile])
    too_many_declines = delay_transaction? && params[:payment_method] == 'credit_card'
    unless current_user
      @user = User.new(params[:user])
    else
      if(params[:funding_source])
        @profile = BillingProfile.find(params[:funding_source])
      end
    end
    respond_to do |format|
      if order_reqs_valid?
        if @certificate_orders
          @order.add_certificate_orders(@certificate_orders)
        else
          @order=current_order
        end
        @credit_card = @profile.build_credit_card
      end
      apply_discounts(@order) #this needs to happen before the transaction but after the final incarnation of the order
      if (@user ? @user.valid? : true) && !too_many_declines &&
          order_reqs_valid? && purchase_successful?
        save_user unless current_user
        save_billing_profile unless (params[:funding_source])
        @order.billing_profile = @profile
        current_user.ssl_account.orders << @order
        record_order_visit(@order)
        @order.credit_affiliate(cookies)
        if @certificate_orders
          clear_cart
          format.html { redirect_to order_path(@ssl_slug, @order) }
        elsif @certificate_order
          current_user.ssl_account.certificate_orders << @certificate_order
          @certificate_order.pay! @gateway_response.success?
          format.html { redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)}
        end
      else
        if too_many_declines
          flash[:error] = 'Too many failed attempts, please wait 1 minute to try again!'
        end
        format.html { render :action => "new" }
      end
    end
    rescue Payment::AuthorizationError => error
      flash.now[:error] = error.message
      render :action => 'new'
  end

  def create_free_ssl
    @order = Order.new(params[:order])
    unless current_user
      @user = User.new(params[:user])
    end
    respond_to do |format|
      if @certificate_orders
        @order.add_certificate_orders(@certificate_orders)
      else
        @order=current_order
      end
      if @order.cents == 0 and @order.line_items.size > 0 and (@user ? @user.valid? : true)
        save_user unless current_user
        current_user.ssl_account.orders << @order
        record_order_visit(@order)
        @order.give_away!
        if @certificate_orders
          clear_cart
          format.html { redirect_to @order }
        elsif @certificate_order
          current_user.ssl_account.certificate_orders << @certificate_order
          @certificate_order.pay! true
          format.html { redirect_to edit_certificate_order_path(@certificate_order)}
        end
      else
        format.html { render :action => "new" }
      end
    end
  end

  def create_multi_free_ssl
    parse_certificate_orders
    unless current_user
      @user = User.new(params[:user])
    end
    respond_to do |format|
      if @user and !@user.valid?
        format.html { render action: "new" }
      elsif @order.cents == 0 and @order.line_items.size > 0 and (@user || current_user)
        save_user unless current_user
        current_user.ssl_account.orders << @order
        record_order_visit(@order)
        @order.give_away!
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

  private

  def set_row_page
    preferred_row_count = current_user.preferred_order_row_count
    @per_page = params[:per_page] || preferred_row_count.or_else("10")

    if @per_page != preferred_row_count
      current_user.preferred_order_row_count = @per_page
      current_user.save(validate: false)
    end

    @p = {page: (params[:page] || 1), per_page: @per_page}
  end


  # admin user refunds line item
  def refund_partial_amount(params)
    refund_amount = @order.make_available_line(@target)
    item_remains  = @order.line_items.select{|li|li.sellable.try("refunded?")}.count==(@order.line_items.count)

    @order.billable.funded_account.add_cents(refund_amount)
    @performed << " and made $#{refund_amount} available to customer"

    #at least 1 lineitem needs to remain unrefunded or refunded amount is less than order total
    if item_remains
      @order.full_refund!
    else
      @order.partial_refund!(params["partial"], refund_amount)
    end
    if (@target.is_a?(LineItem) && @target.sellable.refunded?) || (@target.is_a?(CertificateOrder) && @target.refunded?)
      flash[:notice] = "Line item was successfully credited for #{Money.new(refund_amount).format}."
    end
  end

  # admin user cancels line item
  def refund_partial_cancel(params)
    @performed = "Cancelled partial order #{@target.sellable.ref}, credit or refund were NOT issued."
    @target.sellable.cancel! @target
  end

  def certificate_order_steps
    certificate_order=CertificateOrder.new(params[:certificate_order])
    @certificate_order=Order.setup_certificate_order(certificate: @certificate, certificate_order: certificate_order)
    determine_eligibility_to_buy(@certificate, certificate_order)
    if instance_variable_get("@#{CertificateOrder::RENEWING}")
      @certificate_order.renewal_id=instance_variable_get("@#{CertificateOrder::RENEWING}").id
    end
    @certificate_order.valid?
  end

  def order_reqs_valid?
    @objects_valid ||=
    @order.valid? && (params[:funding_source] ? @profile.valid? :
      @billing_profile.valid?) && (current_user || @user.valid?)
  end

  def purchase_successful?
    return false unless (ActiveMerchant::Billing::Base.mode == :test ? true : @credit_card.valid?)
    @order.description = Order::SSL_CERTIFICATE
    options = @profile.build_info(Order::SSL_CERTIFICATE).merge(
        stripe_card_token: params[:billing_profile][:stripe_card_token],
        owner_email: current_user.nil? ? params[:user][:email] : current_user.ssl_account.get_account_owner.email
      )
    @gateway_response = @order.purchase(@credit_card, options)
    log_declined_transaction(@gateway_response, @credit_card.number.last(4)) unless @gateway_response.success?
    (@gateway_response.success?).tap do |success|
      if success
        flash.now[:notice] = @gateway_response.message
        @order.mark_paid!
        # in case the discount becomes invalid before check out, give it to the customer
        @order.discounts.each do |discount|
          Discount.decrement_counter(:remaining, discount) unless discount.remaining.blank?
        end
        SystemAudit.create(
            owner:  current_user,
            target: @order,
            action: "purchase successful",
            notes:  ""
        )
      else
        flash.now[:error] = @gateway_response.message=~/no match/i ? "CVV code does not match" :
            @gateway_response.message #no descriptive enough
        @order.transaction_declined!
        @certificate_order.destroy unless @certificate_order.blank?
      end
    end
  end

  def find_order
    @order = Order.unscoped{Order.find_by_reference_number(params[:id])}
  end
end
