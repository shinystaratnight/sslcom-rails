class OrdersController < ApplicationController
  layout false, only: [:invoice]
  include OrdersHelper
  #resource_controller
  helper_method :cart_items_from_model_and_id
  before_filter :finish_reseller_signup, :only => [:new], if: "current_user"
  before_filter :find_order, :only => [:show, :invoice, :refund, :change_state]
  before_filter :find_user, :only => [:user_orders]
  before_filter :set_prev_flag, only: [:create, :create_free_ssl, :create_multi_free_ssl]
  before_filter :prep_certificate_orders_instances, only: [:create, :create_free_ssl]
  before_filter :go_prev, :parse_certificate_orders, only: [:create_multi_free_ssl]
#  before_filter :sync_aid_li_and_cart, :only=>[:create],
#    :if=>Settings.sync_aid_li_and_cart
  filter_access_to :all
  filter_access_to :visitor_trackings, :filter_by_state, require: [:index]
  filter_access_to :show,:attribute_check=>true

  def show_cart
    if params[:id] # manually overwrite owned shopping_cart in favor or url specified
      cookies[:cart] = {:value=>ShoppingCart.find_by_guid(params[:id]).content, :path => "/",
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
      if current_user.ssl_account.funded_account.cents > 0
        redirect_to(is_current_order_affordable? ? confirm_funds_url(:order) :
          allocate_funds_for_order_url(:order)) and return
      elsif @certificate_orders && is_order_free?
        create_multi_free_ssl
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
    if @order
      begin
        timeout(10) do
          @doc=Nokogiri::HTML(open("https://www.ssl.com/invoice/index.php?ref_num=#{@order.reference_number}",
                                   {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
          @doc.encoding = 'UTF-8' if @doc.encoding.blank?
          @doc.css("form").first.set_attribute("action", "https://www.ssl.com/invoice/ajax/process.php?ref_num=#{
                                    @order.reference_number}")
          @doc.at_css("script[src*='magic.js']").set_attribute("src", "/ajax/magic.js")
          #render(inline: doc.to_html) and return
        end
      rescue Exception=>e
        print e
      end
    end

    respond_to do |format|
      if @doc
        format.html # new.html.erb
      else
        format.html{ render status: 404}
      end
    end
  end

  def lookup_discount
    @discount=Discount.find_by_ref(params[:discount_code])
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
    performed="canceled #{'partial ' if params["partial"]}order"
    unless @order.blank?
      unless params["partial"]
        if params["return_funds"]
          @order.billable.funded_account.add_cents(@order.amount.cents)
          performed << " and made $#{@order.amount} available to customer"
        end
        @order.full_refund!
        SystemAudit.create(owner: current_user, target: @order, notes: params["refund_reason"], action: performed)
        @order.line_items.each{|li|
          OrderNotifier.request_comodo_refund("refunds@ssl.com", li.sellable.external_order_number, params["refund_reason"]).deliver if(defined? li.sellable.external_order_number)
          OrderNotifier.request_comodo_refund("refunds@comodo.com", li.sellable.external_order_number,
            params["refund_reason"]).deliver if(defined?(li.sellable.external_order_number) && li.sellable.external_order_number)
          OrderNotifier.request_comodo_refund("refunds@ssl.com", $1, params["refund_reason"]).deliver if li.sellable.notes =~ /DV#(\d+)/
        }
      else
        line_item=@order.line_items.find {|li|li.sellable.try(:ref)==params["partial"]}
        @order.billable.funded_account.add_cents(line_item.cents) if params["return_funds"]
        performed << " and made $#{line_item.amount} available to customer"
        #at least 1 lineitem needs to remain unrefunded
        if @order.line_items.select{|li|li.sellable.try("refunded?")}.count==(@order.line_items.count)
          @order.full_refund!
        else
          @order.partial_refund!(params["partial"])
        end
        SystemAudit.create(owner: current_user, target: line_item, notes: params["refund_reason"], action: performed)
        if line_item.sellable.try("external_order_number")
          OrderNotifier.request_comodo_refund("refunds@comodo.com", line_item.sellable.external_order_number, params["refund_reason"]).deliver
          OrderNotifier.request_comodo_refund("support@ssl.com", line_item.sellable.external_order_number, params["refund_reason"], "noreply@ssl.com").deliver
          ComodoApi.revoke_ssl(line_item.sellable, refund_reason: params["refund_reason"])
        end
        if line_item.sellable.notes =~ /DV#(\d+)/
          OrderNotifier.request_comodo_refund("refunds@comodo.com", $1, params["refund_reason"]).deliver
          OrderNotifier.request_comodo_refund("support@ssl.com", $1, params["refund_reason"], "noreply@ssl.com").deliver
          ComodoApi.revoke_ssl(nil, refund_reason: params["refund_reason"], external_order_number: $1)
        end
      end
    end
    redirect_to order_url(@order)
  end

  def change_state
    performed="order changed to #{params[:state]}"
    unless @order.blank?
      @order.send "#{params[:state]}!"
      SystemAudit.create(owner: current_user, target: @order, action: performed)
    end
    redirect_to order_url(@order)
  end

  # GET /orders
  # GET /orders.xml
  def index
    p = {:page => params[:page]}
    @total_amount=nil
    unpaginated =
      if @search = params[:search]
        if current_user.is_admin?
          Order.unscoped{Order.search(params[:search])}
        else
          current_user.ssl_account.orders.unscoped{current_user.ssl_account.orders.search(params[:search]).not_new}
        end
      else
        if current_user.is_admin?
          Order.not_test
        else
          current_user.ssl_account.orders.not_test
        end
      end
    @total_amount=unpaginated.sum(&:cents)
    @total_count=unpaginated.count
    @deposits_amount=unpaginated.joins{line_items.sellable(Deposit)}.sum(&:cents)
    @deposits_count=unpaginated.joins{line_items.sellable(Deposit)}.count
    @orders=unpaginated.paginate(p)

    respond_to do |format|
      format.html { render :action => :index}
      format.xml  { render :xml => @orders }
    end
  end

  def filter_by_state
    p = {:page => params[:page]}
    states = [params[:id]]
    @orders = (current_user.is_admin? ?
        Order.unscoped{Order.includes(:line_items).where{state >> states}.order(:created_at.desc)} :
        current_user.ssl_account.orders.unscoped{
          current_user.ssl_account.orders.includes(:line_items).where{state >> [params[:state]]}.order(:created_at.desc)}).paginate(p)

    respond_to do |format|
      format.html { render :action=>:index}
      format.xml  { render :xml => @orders }
    end
  end

  def visitor_trackings
    p = {:page => params[:page]}
    @orders =
        if @search = params[:search]
          Order.search(params[:search]).paginate(p)
        else
          Order.paginate(p)
        end
  end

  # GET /orders/1
  # GET /orders/1.xml
  def show
    @order.receipt=true
    if @order.description =~ /Deposit/i
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
      if (@user ? @user.valid? : true) &&
          order_reqs_valid? && purchase_successful?
        save_user unless current_user
        save_billing_profile unless (params[:funding_source])
        @order.billing_profile = @profile
        current_user.ssl_account.orders << @order
        record_order_visit(@order)
        credit_affiliate(@order)
        if @certificate_orders
          clear_cart
          format.html { redirect_to @order }
        elsif @certificate_order
          current_user.ssl_account.certificate_orders << @certificate_order
          @certificate_order.pay! @gateway_response.success?
          format.html { redirect_to edit_certificate_order_path(@certificate_order)}
        end
      else
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

  def certificate_order_steps
    certificate_order=CertificateOrder.new(params[:certificate_order])
    @certificate_order=Order.setup_certificate_order(certificate: @certificate, certificate_order: certificate_order)
    determine_eligibility_to_buy(@certificate, certificate_order)
    @certificate_order.renewal_id=
        instance_variable_get("@#{CertificateOrder::RENEWING}").id if
        instance_variable_get("@#{CertificateOrder::RENEWING}")
    @certificate_order.valid?
  end

  def order_reqs_valid?
    @objects_valid ||=
    @order.valid? && (params[:funding_source] ? @profile.valid? :
      @billing_profile.valid?) && (current_user || @user.valid?)
  end

  def purchase_successful?
    return false unless ActiveMerchant::Billing::Base.mode == :test ?
        true : @credit_card.valid?
    @order.amount= BillingProfile::TEST_AMOUNT if (Rails.env=~/development/i && defined?(BillingProfile::TEST_AMOUNT))
    @order.description = [Order::SSL_CERTIFICATE, @order.reference_number].join(" - ")
    @gateway_response = @order.purchase(@credit_card, @profile.build_info(Order::SSL_CERTIFICATE))
    (@gateway_response.success?).tap do |success|
      if success
        flash.now[:notice] = @gateway_response.message
        @order.mark_paid!
        # in case the discount becomes invalid before check out, give it to the customer
        Discount.unscoped {@order.discounts.include_all}.each do |discount|
          Discount.decrement_counter(:remaining, discount) unless discount.remaining.blank?
        end
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
