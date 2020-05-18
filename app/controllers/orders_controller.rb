class OrdersController < ApplicationController
  require 'cgi'
  layout false, only: :invoice
  include OrdersHelper

  helper_method :cart_items_from_model_and_id
  before_action :finish_reseller_signup, only: [:new], if: -> { current_user.present? }
  before_action :find_order, only: [:show, :invoice, :update_invoice, :refund, :refund_merchant, :change_state, :edit, :update, :transfer_order, :update_tags]
  before_action :find_scoped_order, only: [:revoke]
  before_action :set_ssl_slug, only: :show
  before_action :set_prev_flag, only: [:create, :create_free_ssl, :create_multi_free_ssl]
  before_action :prep_certificate_orders_instances, only: [:create, :create_free_ssl]
  before_action :go_prev, :parse_certificate_orders, only: [:create_multi_free_ssl]

  filter_access_to :all
  filter_access_to :visitor_trackings, :filter_by_state, require: [:index]
  filter_access_to :show, :update_invoice, attribute_check: true
  before_action :find_user, :only => [:user_orders]
  before_action :global_set_row_page, only: [:index, :search, :filter_by_state, :visitor_trackings]
  before_action :get_team_tags, only: [:index, :search]

  skip_before_action :verify_authenticity_token, only: [:add_cart]
  
  def update_tags
    if @order
      @taggable = @order
      get_team_tags
      Tag.update_for_model(@taggable, params[:tags_list])
    end
    render json: {
      tags_list: @taggable.nil? ? [] : @taggable.tags.pluck(:name)
    }
  end
  
  def edit
    
  end
  
  def update
    @order ||= Order.find(params[:id])
    if @order.update_attributes(params[:order])
      flash[:notice] = "Order ##{@order.reference_number} has been successfully updated."
      redirect_to edit_order_path(@ssl_slug, @order)
    else
      render :edit
    end
  end

  def transfer_order
    from_team = @ssl_account
    to_team = if current_user.is_system_admins?
      SslAccount.find_by(acct_number: params[:target_team])
    else
      current_user.ssl_accounts.find_by(acct_number: params[:target_team])
    end
    
    if from_team && to_team
      if @order.is_deposit?
        SslAccount.migrate_deposit(from_team, to_team, @order, current_user)
      else
        SslAccount.migrate_orders(from_team, to_team, [@order.reference_number], current_user)
      end

      if to_team.orders.include?(@order)
        flash[:notice] = "Successfully transfered order #{@order.reference_number} to team #{to_team.get_team_name}."
      else
        flash[:error] = "Something went wrong, please try again!"
      end
    else
        flash[:error] = "You do not have access to team #{params[:target_team]}!"
    end
    redirect_to orders_path
  end

  # if the guid is in the URL, populate the browser cart cookie with the db shopping_cart record
  # otherwise if the user is not logged in, populate the db shopping_cart with the contents stored in the browser cart cookie
  def show_cart
    @cart = ShoppingCart.find_by_guid(params[:id]) if params[:id]
    if @cart # manually overwrite owned shopping_cart in favor of url specified
      # cookies[ShoppingCart::CART_KEY] = {:value=>(@cart.content.blank? ? @cart.content : CGI.unescape(@cart.content)), :path => "/",
      #                   :expires => Settings.cart_cookie_days.to_i.days.from_now}
      @cart.update_attribute(:content, nil) if delete_cart_cookie?
      set_cookie(ShoppingCart::CART_GUID_KEY,@cart.guid)
      set_cookie(ShoppingCart::CART_KEY,@cart.content)
    else
      cart = cookies[ShoppingCart::CART_KEY]
      guid = cookies[ShoppingCart::CART_GUID_KEY]
      db_cart = ShoppingCart.find_by_guid(guid)
      if current_user
        if current_user.shopping_cart
          guid=current_user.shopping_cart.guid
          current_user.shopping_cart.update_attribute :content, cart
        # elsif guid && db_cart
        #     db_cart.update_attributes content: cart, user_id: current_user.id
        else # each user should 'own' a db_cart
          guid=UUIDTools::UUID.random_create.to_s
          current_user.create_shopping_cart(guid: guid, content: cart)
        end
        set_cookie(ShoppingCart::CART_GUID_KEY,guid)
      elsif guid && db_cart #assume user is not logged in
        db_cart.update_attribute(:content, cart)
      else
        guid=UUIDTools::UUID.random_create.to_s
        set_cookie(ShoppingCart::CART_GUID_KEY,guid)
        ShoppingCart.create(guid: guid, content: cart)
      end
      redirect_to show_cart_orders_path(id: guid)
    end
    setup_orders
  end
  
  def add_cart
    cart = params[:cart]
    guid = cookies[ShoppingCart::CART_GUID_KEY]
    db_cart = ShoppingCart.find_by_guid(guid)

    if current_user
      if current_user.shopping_cart
        guid = current_user.shopping_cart.guid
        set_cookie(ShoppingCart::CART_GUID_KEY,guid)

        # Get stored cart info
        content = current_user.shopping_cart.content.blank? ? [] : JSON.parse(current_user.shopping_cart.content)
        content = shopping_cart_content(content, cart)
        current_user.shopping_cart.update_attribute :content, content.to_json
      else # each user should 'own' a db_cart
        guid = UUIDTools::UUID.random_create.to_s
        set_cookie(ShoppingCart::CART_GUID_KEY,guid)
        current_user.create_shopping_cart(guid: guid, content: [cart].to_json)
      end
    elsif guid && db_cart #assume user is not logged in
      # Get stored cart info
      content = db_cart.content.blank? ? [] : JSON.parse(db_cart.content)
      content = shopping_cart_content(content, cart)
      db_cart.update_attribute :content, content.to_json
    else
      guid = UUIDTools::UUID.random_create.to_s
      set_cookie(ShoppingCart::CART_GUID_KEY,guid)
      ShoppingCart.create(guid: guid, content: [cart].to_json)
    end

    render :json => {'guid' => guid}
  end

  def change_quantity_in_cart
    returnObj = {}

    # Getting Shopping Cart Info
    if cookies[ShoppingCart::CART_GUID_KEY].blank?
      returnObj['status'] = 'expired'
    else
      shopping_cart = ShoppingCart.find_by_guid(cookies[ShoppingCart::CART_GUID_KEY])

      if shopping_cart
        content = shopping_cart.content.blank? ? [] : JSON.parse(shopping_cart.content)
        cart = cookies[ShoppingCart::CART_KEY].blank? ? [] : JSON.parse(cookies[ShoppingCart::CART_KEY])

        # Changing the quantity if change the quantity
        content = checkout_shopping_cart_content(content, cart)
        shopping_cart.update_attribute :content, content.blank? ? nil : content.to_json

        returnObj['status'] = 'success'
      else
        returnObj['status'] = 'no-exist'
      end
    end

    render :json => returnObj
  end

  def add
    add_to_cart @line_item = ApplicationRecord.find_from_model_and_id(param)
    session[:cart_items].uniq!

    respond_to do |format|
      format.js { render :action => "cart_quantity.js.erb", :layout => false }
    end
  end

  def new
    # If we need to login, make sure we return to cart checkout
    session[:request_referrer] = 'checkout'
    redirect_to new_user_session_path and return unless current_user
    redirect_to new_u2f_path and return unless session[:authenticated]

    if params[:reprocess_ucc] || params[:renew_ucc] || params[:ucc_csr_submit]
      ucc_domains_adjust
    elsif params[:smime_client_enrollment]
      smime_client_enrollment
    else
      if params[:certificate_order] && !single_cert_no_limit_order?
        @certificate = Certificate.for_sale.find_by_product(params[:certificate][:product])
        unless params["prev.x".intern].nil?
          redirect_to buy_certificate_url(@certificate) and return
        end

        if Settings.csr_domains_ui
          managed_domains = params[:managed_domains]
          additional_domains = ''
          managed_domains.each do |domain|
            additional_domains.concat(domain.gsub('csr-', '').gsub('validated-', '').gsub('manual-', '') + ' ')
          end unless managed_domains.blank?

          params[:certificate_order][:certificate_contents_attributes] = {}
          params[:certificate_order][:certificate_contents_attributes]['0'.to_sym] = {}
          params[:certificate_order][:certificate_contents_attributes]['0'.to_sym][:additional_domains] = additional_domains.strip
        end

        render(:template => "submit_csr",
          :layout=>"application") and return unless certificate_order_steps
      else
        # Getting Shopping Cart Info
        shopping_cart = ShoppingCart.find_by_guid(cookies[ShoppingCart::CART_GUID_KEY])

        if shopping_cart
          content = shopping_cart.content.blank? ? [] : JSON.parse(shopping_cart.content)
          cart = cookies[ShoppingCart::CART_KEY].blank? ? [] : JSON.parse(cookies[ShoppingCart::CART_KEY])

          # Changing the quantity if change the quantity
          content = checkout_shopping_cart_content(content, cart)
          shopping_cart.update_attribute :content, content.blank? ? nil : content.to_json

          certificates_from_cookie
        end
      end
      if current_user
        if @certificate_orders && is_order_free?
          create_multi_free_ssl
        elsif ssl_account && ssl_account.no_limit
          create_no_limit_order
        elsif current_user.ssl_account.funded_account.cents > 0
          redirect_to(is_current_order_affordable? ? confirm_funds_url(id: :order) : allocate_funds_for_order_path(id: :order)) && return
        end
      else
        @user_session = UserSession.new
      end
    end
  end

  def remove
    unless session[:cart_items].nil?
      @line_item = ApplicationRecord.find_from_model_and_id(param)
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
        description: 'SSL.com Certificate Order'
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
    cur_invoice = params[:monthly_invoice] || params[:daily_invoice]
    
    found = if cur_invoice
      Invoice.find_by(reference_number: cur_invoice[:invoice_ref])
    else
      Invoice.find_by(order_id: @order.id) if @order
    end
    update = found ? found : Invoice.new(params[:invoice])
    
    no_errors = if found
      update.update_attributes(
        (cur_invoice ? cur_invoice : params[:invoice])
          .keep_if {|k, v| !['order_id', 'invoice_ref'].include?(k)}
      )
    else
      update.save
    end

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
  
  def revoke
    if params[:revoke_all]
      list = @order.cached_certificate_orders
      list.each {|co| co.revoke!(params[:revoke_reason], current_user)}
      
      SystemAudit.create(
        owner: current_user,
        target: @order,
        notes: params[:revoke_reason],
        action: "Revoke all #{list.count} items(s) for order."
      )
      flash[:notice] = "All #{list.count} order item(s) have been revoked."
    else  
      co = CertificateOrder.unscoped.find_by(ref: params[:co_ref])
      co.revoke!(params[:revoke_reason], current_user) if co
      flash[:notice] = "Item ##{params[:co_ref]} has been revoked."
    end
    redirect_to order_path @order
  end

  def refund
    @performed="#{params['cancel_only'] ? 'Cancelled ' : 'Refunded '} #{'partial ' if params["partial"]}order"
    unless @order.blank?
      unless params["partial"] # full refund
        @target = @order
        if params["return_funds"]
          @full_refund_cents = @order.make_available_total
          add_cents_to_funded_account(@full_refund_cents)
          @performed << " and made #{Money.new(@full_refund_cents).format} available to customer."
        end
        params['cancel_only'] ? cancel_entire_order : @order.full_refund!
        notify_ca(params["refund_reason"])
      else # partial refunds or cancel line item
        @target = @order.line_items.find {|li|li.sellable.try(:ref)==params["partial"]}
        @target ||= @order.cached_certificate_orders.find { |co| co.ref==params["partial"] }
        # certificate order has been cancelled but not refunded
        @target ||= @order.certificate_orders.unscoped.find_by(ref: params[:partial])

        refund_partial_amount(params) if params["return_funds"]
        refund_partial_cancel(params) if params["cancel_only"]
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
        if params[:cancel_cert_order]
          co = CertificateOrder.find(params[:cancel_cert_order].to_i)
        end
        
        if params[:mo_ref]
          mo = if current_user.is_system_admins?
            Invoice.find_by(reference_number: params[:mo_ref])
          else
            current_user.ssl_account.invoices.find_by(reference_number: params[:mo_ref])
          end
        end

        amount      = Money.new(co ? @order.make_available_line(co, :merchant) : (params[:refund_amount].to_d * 100))
        refund      = @order.refund_merchant(amount.cents, params[:refund_reason], current_user.id)
        last_refund = @order.refunds.last

        if refund && last_refund && last_refund.successful?
          flash[:notice] = "Successfully refunded merchant for amount #{amount.format}."
          refund_merchant_for_co(co, amount) if co
          refund_merchant_for_mo(mo, amount) if mo
          @order.get_team_to_credit.funded_account.decrement!(:cents, last_refund.amount) if @order.is_deposit?
        else
          flash[:error] = "Refund for #{amount.format} has failed! #{last_refund.message}"
        end
      end
    end
  end
    
  def refund_merchant_for_co(co, amount)
    funded = @order.make_available_funded(co)
    
    co.refund!
    SystemAudit.create(
      owner:  current_user,
      target: co,
      notes:  params["refund_reason"],
      action: "Refunded partial amount for certificate order ##{co.ref}, merchant refund issued for #{amount.format}."
    )
    if funded > 0
      add_cents_to_funded_account(funded)
      flash[:notice] << " And made #{Money.new(funded).format} available to customer."
    end
  end
  
  def refund_merchant_for_mo(mo, amount)
    if mo.merchant_refunded?
      mo.full_refund!
      @order.full_refund! unless @order.fully_refunded?
    else
      mo.partial_refund!
      @order.partial_refund!
    end
    
    SystemAudit.create(
      owner:  current_user,
      target: mo,
      notes:  params["refund_reason"],
      action: "#{@order.billable.get_invoice_label.capitalize} Invoice ##{mo.reference_number}, merchant refund issued for #{amount.format}."
    )
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
    @search = params[:search] || ""
    if is_sandbox? and @search.include?("is_test:true").blank?
      @search << " is_test:true"
    end
    @unpaginated =
      if !@search.blank?
        if current_user.is_system_admins?
          (@ssl_account.try(:orders) ? Order.unscoped{@ssl_account.try(:orders)} : Order.unscoped).where{state << ['payment_declined']}.search(@search)
        else
          current_user.ssl_account.orders.not_new.search(@search)
        end
      else
        if current_user.is_system_admins?
          (@ssl_account.try(:orders) ? Order.unscoped{@ssl_account.try(:orders)} : Order.unscoped).where{state << ['payment_declined']}.order("orders.created_at desc").not_test
        else
          current_user.ssl_account.orders.not_test
        end
      end.uniq

    @orders = @unpaginated.paginate(@p)

    respond_to do |format|
      format.html { render :action => :index}
      format.xml  { render :xml => @orders }
    end
  end

  def filter_by_state
    states = [params[:id]]
    @unpaginated =
      if current_user.is_admin?
        Order.unscoped{Order.includes(:line_items).where{state >> states}.order("orders.created_at desc")}
      else
        current_user.ssl_account.orders.unscoped{
          current_user.ssl_account.cached_orders.includes(:line_items).where{state >> states}.order("orders.created_at desc")}
      end
    @orders = @unpaginated.paginate(@p)

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
    @taggable = @order
    get_team_tags
    if @order.description =~ /Deposit|Funded Account Withdrawal/i
      @deposit = @order
    elsif @order.line_items.count==1
      @certificate_order = @order.cached_certificate_orders.uniq.last
    else
      certificates=[]
      @certificate_orders = @order.cached_certificate_orders.uniq.map{|co|
        unless certificates.include?(co.certificate)
          certificates<<co.certificate
          co
        end}.compact
    end
    set_cookie(:acct,current_user.ssl_account.acct_number)
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
        if @order.invoiced?
          @order.invoice_denied_order(current_user.ssl_account)
        else
          @order.billing_profile = @profile
        end
        save_billing_profile unless params[:funding_source]
        current_user.ssl_account.orders << @order
        record_order_visit(@order)
        @order.credit_affiliate(cookies)
        if @certificate_orders
          clear_cart
          format.html { redirect_to order_path(@ssl_slug, @order) }
        elsif @certificate_order
          current_user.ssl_account.cached_certificate_orders << @certificate_order
          @certificate_order.pay! @gateway_response.success? || @order.invoiced?
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
  
  # Order created for existing UCC certificate order on reprocess/rekey or renew, 
  # or initial CSR submit.
  def ucc_domains_adjust_create
    @reprocess_ucc  = params[:order][:reprocess_ucc]
    @renew_ucc      = params[:order][:renew_ucc]
    @ucc_csr_submit = params[:order][:ucc_csr_submit]

    ucc_or_invoice_params

    order_params = {
      billing_profile_id: params[:funding_source],
      amount:              @target_amount,
      cents:               (@target_amount * 100).to_i,
      description:         Order::DOMAINS_ADJUSTMENT,
      state:               'pending',
      approval:            'approved',
      notes:               get_order_notes,
      invoice_description: params[:order][:order_description],
      wildcard_amount:      params[:order][:wildcard_amount],
      non_wildcard_amount:  params[:order][:nonwildcard_amount],
    }
    
    @order = @reprocess_ucc ? ReprocessCertificateOrder.new(order_params) : Order.new(order_params)
    @order.billable = @ssl_account

    if @funded_amount > 0 && (@order_amount <= @funded_amount)
      # All amount covered by credit from funded account
      ucc_domains_adjust_funded(params)
    else
      # Pay full or partial payment by CC or Paypal
      domains_adjust_hybrid_payment(params)
    end
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
          current_user.ssl_account.cached_certificate_orders << @certificate_order
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

  def smime_client_enroll_create
    ucc_or_invoice_params
    smime_client_enrollment_base
    if @funded_amount > 0 && (@order_amount <= @funded_amount)
      # All amount covered by credit from funded account
      smime_client_enrollment_funded
    else
      # Pay full or partial payment by CC or Paypal
      smime_client_enrollment_hybrid_payment
    end
  end

  private
  
  def single_cert_no_limit_order?
    ssl_account && ssl_account.no_limit && request.referer && request.referer.include?('certificates')
  end

  def add_cents_to_funded_account(cents)
    @order.get_team_to_credit.funded_account.add_cents(cents)
  end
  # ============================================================================
  # S/MIME OR CLIENT ENROLLMENT ORDER
  # ============================================================================
  def smime_client_enrollment
    if current_user
      smime_client_enrollment_base
      if @ssl_account.invoice_required?
        smime_client_enrollment_nolimit
      else
        render :smime_client_enrollment
      end
    else
      redirect_to login_url and return
    end
  end

  def smime_client_enrollment_base
    @emails = params[:emails] || params[:smime_client_enrollment_order][:emails]
    @emails = smime_client_parse_emails(@emails)
    product = params[:certificate] || params[:smime_client_enrollment_order][:certificate]
    @certificate = Certificate.find_by(product: product)
    certificate_orders = smime_client_enrollment_items
    
    @order = SmimeClientEnrollmentOrder.new(
      state: 'new',
      approval: 'approved',
      invoice_description: smime_client_enrollment_notes(certificate_orders.count),
      description: Order::S_OR_C_ENROLLMENT,
      billable_id: certificate_orders.first.ssl_account.try(:id),
      billable_type: 'SslAccount'
    )
    @order.add_certificate_orders(certificate_orders)
  end

  def smime_client_redirect_back
    redirect_to new_order_path(@ssl_slug,
      emails: params[:emails],
      certificate: params[:certificate],
      smime_client_enrollment: true
    )
  end

  def smime_client_enrollment_hybrid_payment
    if current_user && order_reqs_valid? && !@too_many_declines && purchase_successful?
      save_billing_profile unless (params[:funding_source])
      if @order.invoiced?
        @order.invoice_denied_order(current_user.ssl_account)
      else  
        @order.update(billing_profile_id: @profile.try(:id))
        withdraw_funded_account((@funded_amount * 100).to_i) if @funded_amount > 0
      end
      record_order_visit(@order)
      smime_client_enrollment_co_paid
      smime_client_enrollment_registrants
      smime_client_enrollment_validate
      redirect_to order_path(@ssl_slug, @order)
    else
      if @too_many_declines
        flash[:error] = 'Too many failed attempts, please wait 1 minute to try again!'
      end
      smime_client_redirect_back
    end
    rescue Payment::AuthorizationError => error
      flash[:error] = error.message
      smime_client_redirect_back
  end

  def smime_client_enrollment_funded
    withdraw_amount = @order_amount < @funded_amount ? @order_amount : @funded_amount
    withdraw_amount = (withdraw_amount * 100).to_i
    withdraw_amount_str = Money.new(withdraw_amount).format
    
    withdraw_funded_account(withdraw_amount)
    
    if current_user && @order.valid? &&
      ((@ssl_account.funded_account.cents + withdraw_amount) == @funded_account_init)
      @order.update(
        billing_profile_id: nil,
        deducted_from_id: nil,
        state: 'paid'
      )
      record_order_visit(@order)
      smime_client_enrollment_co_paid
      smime_client_enrollment_registrants
      smime_client_enrollment_validate
      flash[:notice] = "Succesfully paid full amount of #{withdraw_amount_str} from funded account for order."
      redirect_to order_path(@ssl_slug, @order)
    else
      flash[:error] = "Something went wrong, did not withdraw #{withdraw_amount_str} from funded account!"
      smime_client_redirect_back
    end
  end

  def smime_client_enrollment_nolimit
    @order.state = 'invoiced'
    @order.invoice_id = Invoice.get_or_create_for_team(@ssl_account).try(:id)
    smime_client_enrollment_co_paid if @order.save
    redirect_to order_path(@ssl_slug, @order)
  end
  # ============================================================================
  # UCC Certificate reprocess/rekey helper methods for 
  #   Invoiced Order:       will be added to monthly invoice to be charged later
  #   Free Order:           no additional domains, or fully covered by funded account credit
  #   Hybrid Payment Order: amount paid by BOTH funded account and (CC or Paypal)
  # ============================================================================
  def reprocess_ucc_redirect_back
    redirect_to new_order_path(@ssl_slug,
      co_ref: @certificate_order.ref, cc_ref: @certificate_content.ref, reprocess_ucc: true
    )
  end
    
  def ucc_domains_adjust_funded(params)
    withdraw_amount     = @order_amount < @funded_amount ? @order_amount : @funded_amount
    withdraw_amount     = (withdraw_amount * 100).to_i
    withdraw_amount_str = Money.new(withdraw_amount).format
    
    withdraw_funded_account(withdraw_amount)
    
    if current_user && @order.valid? &&
      ((@ssl_account.funded_account.cents + withdraw_amount) == @funded_account_init)
      reprocess_ucc_order_free(params)
      ucc_update_domain_counts
      flash[:notice] = "Succesfully paid full amount of #{withdraw_amount_str} from funded account for order."
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)
    else
      flash[:error] = "Something went wrong, did not withdraw #{withdraw_amount_str} from funded account!"
      reprocess_ucc_redirect_back
    end
  end
    
  def domains_adjust_hybrid_payment(params)
    if current_user && order_reqs_valid? && !@too_many_declines && purchase_successful?
      save_billing_profile unless (params[:funding_source])
      if @order.invoiced?
        @order.invoice_denied_order(current_user.ssl_account)
      else  
        @order.billing_profile = @profile
        @certificate_order.add_reproces_order @order
        withdraw_funded_account((@funded_amount * 100).to_i) if @funded_amount > 0
      end
      record_order_visit(@order)
      ucc_update_domain_counts
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)
    else
      if @too_many_declines
        flash[:error] = 'Too many failed attempts, please wait 1 minute to try again!'
      end
      reprocess_ucc_redirect_back
    end
    rescue Payment::AuthorizationError => error
      flash[:error] = error.message
      reprocess_ucc_redirect_back
  end
  
  def reprocess_ucc_order_free(params)
    # On UCC reprocess, order is FREE if
    #   fully covered by funded account, or
    #   there were no additional domains from initial order
    @order.billing_profile_id = nil
    @order.deducted_from_id = nil
    @order.state = 'paid'
    @certificate_order.add_reproces_order @order
    record_order_visit(@order)
    @order.lock!
    @order.save
    # In case credits were used to cover the cost of order.
    ucc_update_domain_counts
  end
  
  def create_no_limit_order
    single_certificate = single_cert_no_limit_order?
    ssl_account_id = ssl_account.id

    if single_certificate
      @certificate_order = certificates_from_cookie.last
      @certificate_order.quantity = 1
      @order = Order.new(
        amount: @certificate_order.amount,
        billable_id: ssl_account_id,
        billable_type: 'SslAccount',
        state: 'invoiced'
      )
      @order.add_certificate_orders([@certificate_order])
      if @order.save
        @certificate_order = @order.cached_certificate_orders.first
        @certificate_order.update(
          ssl_account_id: ssl_account_id, workflow_state: 'paid'
        )
      end
    else
      setup_orders
      @order.billable_id = ssl_account_id
      @order.billable_type = 'SslAccount'
      if @order.save
        @order.cached_certificate_orders.update_all(
          ssl_account_id: ssl_account_id, workflow_state: 'paid'
        )
      end
      clear_cart
    end
    
    @order.update(
      state: 'invoiced',
      invoice_id: Invoice.get_or_create_for_team(ssl_account_id).try(:id),
      approval: 'approved',
      invoice_description: Order::SSL_CERTIFICATE
    )
    record_order_visit(@order)

    # flash[:notice] = "Order in the amount of #{@order.amount.format}
    #     will appear on the #{ssl_account.get_invoice_label} invoice."
    if single_certificate
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order.ref)
    else
      redirect_to order_path(@ssl_slug, @order)
    end
  end

  def add_to_payable_invoice(params)
    invoice = Invoice.get_or_create_for_team(@ssl_account)
    @order = current_order_reprocess_ucc if @reprocess_ucc
    
    if @renew_ucc || @ucc_csr_submit
      @order        = @ssl_account.purchase(@certificate_order)
      @order.cents  = @amount * 100
      @order.amount = @amount
    end
    @order.description = Order::DOMAINS_ADJUSTMENT
    @order.state       = 'invoiced'
    @order.notes       = get_order_notes
    @order.invoice_id  = invoice.id
    @order.approval    = 'approved'
    @order.invoice_description = params[:order_description]
    @order.wildcard_amount     = params[:wildcard_amount]
    @order.non_wildcard_amount = params[:nonwildcard_amount]
    
    @certificate_order.add_reproces_order @order
    ucc_update_domain_counts
    record_order_visit(@order)
  end
    
  def ucc_domains_adjust
    if current_user
      @certificate_order = if current_user.is_system_admins?
        CertificateOrder.find_by(ref: params[:co_ref])
      else
        current_user.ssl_account.cached_certificate_orders.find_by(ref: params[:co_ref])
      end
      @ssl_account = @certificate_order.try(:ssl_account)
      @certificate_content = @certificate_order.certificate_contents.find_by(ref: params[:cc_ref])

      @amount = if params[:renew_ucc] || params[:ucc_csr_submit]
        params[:order_amount].to_f
      else
        @certificate_order.ucc_prorated_amount(@certificate_content, find_tier)
      end
      params[:reprocess_ucc] ? ucc_domains_adjust_reprocess : ucc_domains_adjust_other
    else
      redirect_to login_url and return
    end
  end
  
  def ucc_domains_adjust_other
    @renew_ucc = params[:renew_ucc]
    @ucc_csr_submit = params[:ucc_csr_submit]
    
    if @ssl_account.invoice_required? || @amount == 0
      if @ssl_account.invoice_required? && @amount > 0 # Invoice Order, do not charge
        add_to_payable_invoice(params)
        # flash[:notice] = "The domains adjustment amount of #{@order.amount.format}
        #   will appear on the #{@ssl_account.get_invoice_label} invoice."
      end
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)
    else
      render 'ucc_domains_adjust'
    end
  end
    
  def ucc_domains_adjust_reprocess
    @reprocess_ucc = true
    
    if @ssl_account.invoice_required? || @amount == 0
      if @amount == 0 # Reprocess is free, no additional domains added
        @order = ReprocessCertificateOrder.new(
          amount:      0,
          cents:       0,
          description: Order::DOMAINS_ADJUSTMENT,
          notes:       reprocess_ucc_notes,
          approval:    'approved'
        )
        @order.billable = @ssl_account
        reprocess_ucc_order_free(params)
        flash[:notice] = "This UCC certificate reprocess is free due to no additional domains."
      end
      
      if @ssl_account.invoice_required? && @amount > 0 # Invoice Order, do not charge
        add_to_payable_invoice(params)
        # flash[:notice] = "This UCC reprocess in the amount of #{Money.new(@amount).format}
        #   will appear on the #{@ssl_account.get_invoice_label} invoice."
      end
      redirect_to edit_certificate_order_path(@ssl_slug, @certificate_order)
    else
      render 'ucc_domains_adjust'
    end
  end
  
  # admin user refunds line item
  def refund_partial_amount(params)
    refund_amount = @order.make_available_line(@target)
    all_refunded  = @order.line_items.select{|li|li.sellable.try("refunded?")}.count == @order.line_items.count
    refund_amount_f = Money.new(refund_amount).format
    
    add_cents_to_funded_account(refund_amount)
    @performed << " and made #{refund_amount_f} available to customer"

    # at least 1 lineitem needs to remain unrefunded or refunded amount is less than order total
    if all_refunded || (@order.cents <= refund_amount)
      @order.full_refund!
    else
      @order.partial_refund!(params["partial"], refund_amount)
    end
    if (@target.is_a?(LineItem) && @target.sellable.refunded?) || (@target.is_a?(CertificateOrder) && @target.refunded?)
      flash[:notice] = "Line item was successfully credited for #{refund_amount_f}."
    end
  end

  # admin user cancels line item
  def refund_partial_cancel(params)
    if @order.line_items.count == 1 #order has only one item, cencel entire order
      @target = @order
      cancel_entire_order
    else  
      @performed = "Cancelled partial order #{@target.sellable.ref}, credit or refund were NOT issued."
      @target.sellable.cancel! @target
    end
  end

  # admin user cancels entire order and all of it's line items
  def cancel_entire_order
    @performed = "Cancelled entire order #{@target.reference_number}, credit or refund were NOT issued."
    @target.cancel! unless @target.canceled?
    if @target.canceled? && @target.invoice
      @target.update(invoice_id: nil)
    end
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

  def find_order
    @order = Order.unscoped{Order.find_by_reference_number(params[:id])}
  end

  def find_scoped_order
    @order = (current_user.is_system_admins? ? Order : current_user.orders).find_by_reference_number(params[:id])
  end

  def checkout_shopping_cart_content(content, cart)
    new_contents = []
    # Check to be same the quantity
    cart.each do |cookie|
      same = content.detect{|cont| cont[ShoppingCart::LICENSES] == cookie[ShoppingCart::LICENSES] &&
          !cont[ShoppingCart::DOMAINS].blank? && !cookie[ShoppingCart::DOMAINS].blank? &&
          cont[ShoppingCart::DOMAINS].split(Certificate::DOMAINS_TEXTAREA_SEPARATOR).size == cookie[ShoppingCart::DOMAINS].split(Certificate::DOMAINS_TEXTAREA_SEPARATOR).size &&
          (cont[ShoppingCart::DOMAINS].split(Certificate::DOMAINS_TEXTAREA_SEPARATOR) &
              cookie[ShoppingCart::DOMAINS].split(Certificate::DOMAINS_TEXTAREA_SEPARATOR)).size == cont[ShoppingCart::DOMAINS].split(Certificate::DOMAINS_TEXTAREA_SEPARATOR).size &&
          cont[ShoppingCart::DURATION] == cookie[ShoppingCart::DURATION] &&
          cont[ShoppingCart::PRODUCT_CODE] == cookie[ShoppingCart::PRODUCT_CODE] &&
          cont[ShoppingCart::SUB_PRODUCT_CODE] == cookie[ShoppingCart::SUB_PRODUCT_CODE] &&
          cont[ShoppingCart::RENEWAL_ORDER] == cookie[ShoppingCart::RENEWAL_ORDER] &&
          cont[ShoppingCart::AFFILIATE] == cookie[ShoppingCart::AFFILIATE]
      }

      same[ShoppingCart::QUANTITY] = cookie[ShoppingCart::QUANTITY].to_i if !same.blank? &&
          same[ShoppingCart::QUANTITY].to_i != cookie[ShoppingCart::QUANTITY].to_i

      new_contents << (same.blank? ? cookie : same)
    end
    new_contents = '' if new_contents.size == 0

    return new_contents
  end

  def shopping_cart_content(content, cart)
    match = true
    idx = -1

    # Check to exist same info
    content.each_with_index do |cookie, i|
      match = true
      cookie.keys.each do |key|
        if key != ShoppingCart::QUANTITY && key != ShoppingCart::AFFILIATE && cookie[key] != cart[key]
          match = false
          break
        end
      end

      if match
        idx = i
        break
      end
    end

    # Update content based on existing same one.
    if idx == -1
      cart[ShoppingCart::QUANTITY] = 1
      if content.kind_of?(Array)
        content << cart
      else
        content = [cart]
      end
    else
      content[idx][ShoppingCart::QUANTITY] = content[idx][ShoppingCart::QUANTITY].to_i + 1
    end

    return content
  end
end
