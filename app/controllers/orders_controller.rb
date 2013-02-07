class OrdersController < ApplicationController
  include OrdersHelper
  #resource_controller
  helper_method :cart_items_from_model_and_id
  before_filter :finish_reseller_signup, :only => [:new], if: "current_user"
  before_filter :find_order, :only => [:show]
  before_filter :find_user, :only => [:user_orders]
  before_filter :set_prev_flag, only: [:create, :create_free_ssl, :create_multi_free_ssl]
  before_filter :prep_certificate_orders_instances, only: [:create, :create_free_ssl]
  before_filter :go_prev, :parse_certificate_orders, only: [:create_multi_free_ssl]
#  before_filter :sync_aid_li_and_cart, :only=>[:create],
#    :if=>Settings.sync_aid_li_and_cart
  filter_access_to :all
  filter_access_to :visitor_trackings, :lookup_discount, require: [:index]
  filter_access_to :show,:attribute_check=>true

  def show_cart
    certificates_from_cookie
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
      if current_user.ssl_account.is_registered_reseller?
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

  # GET /orders
  # GET /orders.xml
  def index
    p = {:page => params[:page]}
    @orders = if @search = params[:search]
      (current_user.is_admin? ?
        Order.not_test.search(params[:search]) :
        current_user.ssl_account.orders.not_test.
          search(params[:search]).not_new).paginate(p)
    else
      ((current_user.is_admin? ? Order.not_test :
        current_user.ssl_account.orders.not_new.not_test).paginate(p))
    end

    respond_to do |format|
      format.html { render :action => :index}
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
    if @order.description == 'Deposit'
      @deposit = @order
    elsif @order.line_items.count==1
      @certificate_order = @order.line_items.map(&:sellable).flatten.uniq.last
    else
      @certificate_orders = @order.line_items.map(&:sellable).flatten.uniq.
          select{|cert|!cert.line_item_qty.blank?}
    end
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
    if (params[:discount_code])
      @order.discounts<<Discount.find_by_ref(params[:discount_code]) if Discount.find_by_ref(params[:discount_code])
    end
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
          build_certificate_contents(@certificate_orders, @order)
        else
          @order=current_order
        end
        @credit_card = @profile.build_credit_card
      end
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
        build_certificate_contents(@certificate_orders, @order)
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
    @certificate_order=setup_certificate_order(@certificate, certificate_order)
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
    @order.amount= ::GATEWAY_TEST_CODE if defined?(::GATEWAY_TEST_CODE)
    @order.description = Order::SSL_CERTIFICATE
    @gateway_response = @order.purchase(@credit_card, @profile.build_info(Order::SSL_CERTIFICATE))
    (@gateway_response.success?).tap do |success|
      if success
        flash.now[:notice] = @gateway_response.message
        @order.mark_paid!
      else
        flash.now[:error] = @gateway_response.message=~/no match/i ? "CVV code does not match" :
            @gateway_response.message #no descriptive enough
        @order.transaction_declined!
        @certificate_order.destroy unless @certificate_order.blank?
      end
    end
  end

  def save_user
    @user.create_ssl_account
    @user.roles << Role.find_by_name(Role::CUSTOMER)
    @user.signup!(params)
    @user.activate!(params)
    @user.deliver_activation_confirmation!
    @user_session = UserSession.create(@user)
    @current_user_session = @user_session
    Authorization.current_user = @current_user = @user_session.record
  end

  def find_order
    @order = Order.find_by_reference_number(params[:id])
  end
end
