class OrdersController < ApplicationController
  include OrdersHelper
  resource_controller
  helper_method :cart_items_from_model_and_id
  before_filter :find_studio, :only => [:studio_orders]
  before_filter :find_user, :only => [:user_orders]
  before_filter :find_affiliate, :only => [:affiliate_orders]
  before_filter :require_current_user, :only => [:user_orders]
  before_filter :require_affiliate_ownership, :only => [:affiliate_orders]
  before_filter :sync_aid_li_and_cart, :only=>[:create],
    :if=>AppConfig.sync_aid_li_and_cart
#  filter_access_to :all, :attribute_check=>false

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
        @certificate = Certificate.find_by_product(params[:certificate][:product])
        unless params["prev.x".intern].nil?
          redirect_to buy_certificate_url(@certificate) and return
        end
      render(:template => "/certificates/buy",
        :layout=>"application") and return unless certificate_order_steps
    else
      certificates_from_cookie
    end
    if current_user && current_user.ssl_account.is_registered_reseller?
      redirect_to(is_current_order_affordable? ? confirm_funds_url(:order) :
        allocate_funds_for_order_url(:order)) and return
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
        Order.search(params[:search]) :
        current_user.ssl_account.orders.
          search(params[:search]).not_new).paginate(p)
    else
      ((current_user.is_admin? ? Order :
        current_user.ssl_account.orders.not_new).paginate(p))
    end

    respond_to do |format|
      format.html { render :action => :index}
      format.xml  { render :xml => @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.xml
  def show
    order = Order.find_by_reference_number(params[:id])
    order.receipt=true
    if order.description == 'Deposit'
      @deposit = order
    elsif order.line_items.count==1
      @order = order
      @certificate_order = order.line_items.map(&:sellable).flatten.uniq.last
    else
      @order = order
      @certificate_orders = order.line_items.map(&:sellable).
        flatten.uniq.find_all{|cert|!cert.line_item_qty.blank?}
    end
    respond_to do |format|
      if order.line_items.count==1
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
      if params[:certificate_order]
        @certificate_order=CertificateOrder.new(params[:certificate_order])
        @certificate = Certificate.find_by_product(params[:certificate][:product])
        if params["prev.x".intern] || !certificate_order_steps
          @certificate_order.has_csr=true
          format.html {render(:template => "/certificates/buy",
            :layout=>"application")}
        end
      else
        unless params["prev.x".intern].nil?
          redirect_to show_cart_orders_url and return
        end
        certificates_from_cookie
      end
      if order_reqs_valid?
        if @certificate_orders
          build_certificate_contents(@certificate_orders, @order)
        else
          @order=current_order
        end
        @credit_card = ActiveMerchant::Billing::CreditCard.new({
          :first_name => @profile.first_name,
          :last_name  => @profile.last_name,
          :number     => @profile.card_number,
          :month      => @profile.expiration_month,
          :year       => @profile.expiration_year,
          :verification_value => @profile.security_code
        })
        @credit_card.type = 'bogus' if defined?(::GATEWAY_TEST_CODE)
      end
      if (@user ? @user.valid? : true) &&
          order_reqs_valid? && purchase_successful?
        save_user unless current_user
        save_billing_profile unless (params[:funding_source])
        @order.billing_profile = @profile
        current_user.ssl_account.orders << @order
        @order.save
        if @certificate_orders
          clear_cart
          format.html { redirect_to @order }
        elsif @certificate_order
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

  private

  def certificate_order_steps
    @certificate_order=CertificateOrder.new(params[:certificate_order])
    determine_eligibility_to_buy
    setup_certificate_order
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
      :description => Order::SSL_CERTIFICATE
    }
    @gateway_response = @order.purchase(@credit_card, options)
    if @gateway_response.success?
      flash.now[:notice] = @gateway_response.message
      true
    else
      flash.now[:error] = @gateway_response.message
      false
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
end
