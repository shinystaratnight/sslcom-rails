# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  layout 'application'
  #include Authentication
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found
  rescue_from ActionController::RoutingError, :with => :not_found
  rescue_from AbstractController::ActionNotFound, :with => :not_found
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :current_user_session, :current_user, :is_reseller, :cookies,
    :cart_contents, :cart_products, :certificates_from_cookie, "is_iphone?", "hide_dcv?", :free_qty_limit,
    "hide_documents?", "hide_both?", "hide_validation?"
  before_filter :detect_recert, except: [:renew, :reprocess]
  before_filter :set_current_user
  before_filter :identify_visitor, :record_visit,
                if: "Settings.track_visitors"
  before_filter :finish_reseller_signup, if: "current_user"
  before_filter :team_base, if: "params[:ssl_slug] && current_user"
  before_filter :set_ssl_slug, :load_notifications
  after_filter :set_access_control_headers

#  hide_action :paginated_scope

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def permission_denied
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url :subdomain=>Settings.root_subdomain
      return false
    else
      flash[:error] = "You currently do not have permission to access that page."
      redirect_to account_path
    end
  end

  def paginated_scope(relation)
    instance_variable_set "@#{controller_name}", relation.paginate(params[:page])
  end

  def is_reseller?
    current_user && current_user.ssl_account.is_registered_reseller?
  end

  def save_user
    @user.create_ssl_account([Role.get_owner_id])
    @user.signup!(params)
    @user.activate!(params)
    @user.deliver_activation_confirmation!
    @user_session = UserSession.create(@user)
    @current_user_session = @user_session
    Authorization.current_user = @current_user = @user_session.record
  end

  def find_tier
    @tier =''
    if current_user and current_user.ssl_account.has_role?('reseller')
      @tier = current_user.ssl_account.reseller_tier_label + 'tr'
    elsif cookies[:r_tier]
      @tier = cookies[:r_tier] + 'tr'
    end
  end

  def add_to_cart line_item
    session[:cart_items] << line_item.model_and_id
  end

  def apply_discounts(order)
    if (params[:discount_code])
      order.temp_discounts =[]
      order.temp_discounts<<Discount.viable.find_by_ref(params[:discount_code]).id if Discount.viable.find_by_ref(params[:discount_code])
    end
  end

  # returns the cart cookie with reseller tier as an array
  def cart_contents
    find_tier
    cart = cookies[:cart]
    cart.blank? ? {} : JSON.parse(cart).each{|i|i['pr']=i['pr']+@tier if(i['pr'] && !i['pr'].ends_with?(@tier) && @tier)}
  end

  def cart_products
    cart_contents.collect {|cart_item|
      pr = cart_item[ShoppingCart::PRODUCT_CODE]
      if pr.blank?
        nil
      else
        ActiveRecord::Base.find_from_model_and_id(pr)
      end
    }.compact
  end

  def delete_cart_items
    cookies.delete :cart
  end

  def save_cart_items(items)
    cookies[:cart] = {:value=>JSON.generate(items), :path => "/",
      :expires => Settings.cart_cookie_days.to_i.days.from_now}
  end

  def free_qty_limit
    qty=current_user ?
        Certificate::FREE_CERTS_CART_LIMIT - current_user.ssl_account.certificate_orders.unused_free_credits.count :
        Certificate::FREE_CERTS_CART_LIMIT
    (qty <= 0) ? 0 : qty
  end

  # parse the cookie and build @certificate_orders
  def certificates_from_cookie
    certs=cart_contents
    @certificate_orders=[]
    return @certificate_orders if certs.blank?
    limit=free_qty_limit
    Order.certificates_order(certificates: certs, max_free: limit,
                             certificate_orders: @certificate_orders, current: current_user)
  end

  def old_certificates_from_cookie
    @certificate_orders=[]
    return @certificate_orders unless cookies[:cart]
    Order.cart_items session, cookies
    certs=cookies[:cart].split(":")
    certs.each do |c|
      parts = c.split(",")
      certificate_order = CertificateOrder.new :server_licenses=>parts[2],
        :duration=>parts[1], :quantity=>parts[4].to_i
      certificate_order.certificate_contents.build :domains=>parts[3]
      certificate = Certificate.for_sale.find_by_product(parts[0])
      unless current_user.blank?
        current_user.ssl_account.clear_new_certificate_orders
        next unless current_user.ssl_account.can_buy?(certificate)
      end
      #adjusting duration to reflect number of days validity
      duration = certificate.duration_in_days(certificate_order.duration)
      certificate_order.certificate_contents[0].duration = duration
      if certificate.is_ucc? || certificate.is_wildcard?
        psl = certificate.items_by_server_licenses.find{|item|
          item.value==duration.to_s}
        so = SubOrderItem.new(:product_variant_item=>psl,
          :quantity=>certificate_order.server_licenses.to_i,
          :amount=>psl.amount*certificate_order.server_licenses.to_i)
        certificate_order.sub_order_items << so
        if certificate.is_ucc?
          pd = certificate.items_by_domains.find_all{|item|
            item.value==duration.to_s}
          additional_domains = (certificate_order.domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
          so = SubOrderItem.new(:product_variant_item=>pd[0],
            :quantity=>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
            :amount=>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
          certificate_order.sub_order_items << so
          if additional_domains > 0
            so = SubOrderItem.new(:product_variant_item=>pd[1],
              :quantity=>additional_domains,
              :amount=>pd[1].amount*additional_domains)
            certificate_order.sub_order_items << so
          end
        end
      end
      unless certificate.is_ucc?
        pvi = certificate.items_by_duration.find{|item|item.value==duration.to_s}
        so = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
          :amount=>pvi.amount)
        certificate_order.sub_order_items << so
      end
      certificate_order.amount = certificate_order.sub_order_items.map(&:amount).sum
      certificate_order.certificate_contents[0].
        certificate_order = certificate_order
      @certificate_orders << certificate_order if certificate_order.valid?
    end
  end

  def find_certificate_orders(options={})
    return CertificateOrder.none unless current_user # returns null set. Rails 4 is CertificateOrder.none
    if @search = params[:search]
      #options.delete(:page) if options[:page].nil?
      (current_user.is_admin? ?
        (CertificateOrder.unscoped{
          (@ssl_account.try(:certificate_orders) || CertificateOrder).search_with_csr(params[:search], options)}) :
            current_user.ssl_account.certificate_orders.search_with_csr(params[:search], options)).order_by_csr
    else
      (current_user.is_admin? ?
          (@ssl_account.try(:certificate_orders) || CertificateOrder).not_test.find_not_new(options) :
            current_user.ssl_account.certificate_orders.not_test.not_new(options))
    end
  end

  def find_certificate_orders_with_site_seals
    return CertificateOrder.where('1=0') unless current_user # returns null set. Rails 4 is CertificateOrder.none
    if @search = params[:search]
      (current_user.is_admin? ?
        (CertificateOrder.search_with_csr(params[:search])) :
        current_user.ssl_account.certificate_orders.
          search_with_csr(params[:search])).has_csr
    else
      (current_user.is_admin? ?
        CertificateOrder.find_not_new(:include=>:site_seal) :
        current_user.ssl_account.certificate_orders.not_new(:include=>:site_seal))
    end
  end

  def set_ssl_slug(target_user=nil)
    user = target_user || current_user
    if user
      ssl = user.ssl_account
      @ssl_slug = if user.is_system_admins?
        nil
      else
        if ssl 
          ssl.ssl_slug || ssl.acct_number
        end
      end
    end
  end

  def not_found
    render :text => "404 Not Found", :status => 404
  end

  protected

  def set_prev_flag
    @prev=true if params["prev.x".intern]
  end

  def prep_certificate_orders_instances
    if params[:certificate_order]
      @certificate = Certificate.for_sale.find_by_product(params[:certificate][:product])
      co_valid = certificate_order_steps
      if params["prev.x".intern] || !co_valid
        @certificate_order.has_csr=true
        render(:template => "/certificates/buy", :layout=>"application")
        return false
      end
    else
      unless params["prev.x".intern].nil?
        redirect_to show_cart_orders_url and return
        return false
      end
      certificates_from_cookie
    end
  end

  def set_current_user
      Authorization.current_user = current_user
      if current_user and current_user.ssl_accounts.blank?
        current_user_session.destroy
        Authorization.current_user=nil
        return false
      end
  end

  def setup_orders
    #will create @certificate_orders below
    certificates_from_cookie
    @order = Order.new(:amount=>(current_order.amount.to_s.to_i or 0))
    @order.add_certificate_orders(@certificate_orders)
  end

  def parse_certificate_orders
    if params[:certificate_order]
      @certificate_order = current_user.ssl_account.certificate_orders.current
      @order = current_order
    else
      setup_orders
    end
  end

  def go_back_to_buy_certificate
    #need to create new objects and delete the existing ones
    @certificate_order = current_user.ssl_account.
      certificate_orders.detect(&:new?)
    @certificate = @certificate_order.certificate
    @certificate_content = @certificate_order.certificate_content.dup
    @certificate_order = current_user.ssl_account.
      certificate_orders.detect(&:new?).dup
    @certificate_order.duration = @certificate.duration_index(@certificate_content.duration)
    @certificate_order.has_csr = true
    render(:template => "/certificates/buy", :layout=>"application")
  end

  def create_ssl_certificate_route(user)
#    if params[:certificate]
#      user.ssl_account.is_registered_reseller? ?
#          ["submit", certificate_orders_url] : ["redirect", new_order_url]
##    elsif params[:free_certificate]
##      create_free_ssl_orders_path
##    elsif params[:free_certificates]
##      create_multi_free_ssl_orders_path
##    else #assume non-free certificates
#    end
    if user.ssl_account.is_registered_reseller?
      ["submit", params[:certificate] ? certificate_orders_url : new_order_url]
    else
      if params[:certificate] && params[:certificate][:product]
        #assume a single cert sale
        params[:certificate][:product]=="free" ? ["submit", ""] : ["",""]
      else
        #shopping cart checkout
        shopping_cart_amount > 0 ? ["",""] : ["submit", ""]
      end
#      ["redirect", new_order_url]
    end
  end

  def shopping_cart_amount
    certificates_from_cookie.sum(&:amount)
  end

  #co - certificate order
  def hide_validation?(co)
    return false if current_user.blank?
    !co.certificate_content.show_validation_view? && (!current_user.is_admin? || co.is_test?)
  end

=begin
  def responder
    EnhancedResponder
  end
=end

  def handle_unverified_request
    # raise an exception
    fail ActionController::InvalidAuthenticityToken
    # or destroy session, redirect
    if current_user_session
      current_user_session.destroy
    end
    redirect_to root_url
  end

  #derive the model name from the controller. egs UsersController will return User
  def self.permission
    return name = self.name.gsub('Controller','').singularize.split('::').last.constantize.name rescue nil
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  #load the permissions for the current user so that UI can be manipulated
  def load_permissions
    @current_permissions = current_user.permissions.collect{|i| [i.subject_class, i.action]}
  end

  def find_ssl_account
    @ssl_account = if params[:ssl_slug] and request[:action]!="validate_ssl_slug"
      SslAccount.find_by_acct_number(params[:ssl_slug]) || SslAccount.find_by_ssl_slug(params[:ssl_slug])
    else
      current_user.ssl_account if current_user
    end
  end

  def load_notifications
    if current_user 
      if current_user.pending_account_invites?
        @team_invites = []
        current_user.get_pending_accounts.each do |invite|
          new_params       = {ssl_account_id: invite[:ssl_account_id], token: invite[:approval_token], to_teams: true}
          invite[:accept]  = approve_account_invite_user_path(current_user, new_params)
          invite[:decline] = decline_account_invite_user_path(current_user, new_params)
          invite.delete(:approval_token)
          @team_invites   << invite
        end
      end
      if current_user.persist_notice && current_user.assignments.where.not(role_id: Role.cannot_be_invited)
        flash[:info_activation] = true
      end
    end
  end

  private

  #Saves a cookie using a hash
  # <tt>options</tt> - Contains keys name, value (a hash), path, and expires
  def save_cookie(options)
    c={:value=>JSON.generate(options[:value]), :path => options[:path],
      :expires => options[:expires]}
    c.merge!(:domain=>options[:domain]) if options[:domain]
    cookies[options[:name]] = c
  end

  def get_cookie(name)
    name = name.to_sym if name.is_a? String
    cookies[name].blank? ? {} : JSON.parse(cookies[name])
  end

  #if in process of recerting (renewal, reprocess, etc), this sets instance
  #variables from params. Only one type allowed at a time.
  def detect_recert
    CertificateOrder::RECERTS.each do |r|
      unless params[r.to_sym].blank?
        recert=CertificateOrder.find_by_ref(params[r.to_sym])
        instance_variable_set("@#{r.to_sym}", recert) if recert
        break
      end
    end
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find(:shadow).try(:user) ? UserSession.find(:shadow) : UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless (current_user || @current_admin)
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_admin
    user_not_authorized unless current_user.is_admin?
  end

  def require_no_user
    if current_user
      store_location
      cookies[:acct] = {:value=>current_user.ssl_account.acct_number, :path => "/", :expires => Settings.
          cart_cookie_days.to_i.days.from_now} if current_user.is_admin?
      flash[:notice] = "You must be logged out to access page '#{request.fullpath}'"
      redirect_to account_url
      return false
    end
  end

  def go_prev
    unless params["prev.x".intern].nil?
      if params[:certificate_order]
        go_back_to_buy_certificate
      else
        redirect_to(show_cart_orders_url)
      end
      false
    end
  end

  def store_location
    session[:return_to] = request.url
  end

  def redirect_back_or_default(default)
    go_to = (session[:return_to] == logout_path) ? nil : session[:return_to]
    session[:return_to] = nil
    redirect_to(go_to || default)
  end

  def finish_reseller_signup
    blocked = %w(certificate_orders orders site_seals validations ssl_accounts users)
    if current_user.ssl_account
      redirect_to new_account_reseller_url and return if
          (current_user.ssl_account.reseller ?
              # following line avoids loop with last condition in ResellersController#new comparing reseller.complete?
              # with ssl_account.is_new_reseller?
              !current_user.ssl_account.reseller.complete? :
              current_user.ssl_account.is_new_reseller?) and blocked.include?(controller_name)
    end
  end

  def user_not_authorized
    render 'site/403_forbidden', status: 403
  end

  def save_billing_profile
    profile = current_user.ssl_account.billing_profiles.find_by_card_number @billing_profile.card_number
    current_user.ssl_account.billing_profiles.delete profile unless profile.nil?
    current_user.ssl_account.billing_profiles << @billing_profile
  end

  #this is a band-aid function to make sure the number of item in cookies
  #aid_li and cart match. however, the problem causing the unsync was found.
  #this function can be turned back on by the Settings.sync_aid_li_and_cart
  #variable
  def sync_aid_li_and_cart
    if cookies[:aid_li] && cookies[:cart]
      aid_li=cookies[:aid_li].split(":")
      cart=cart_contents
      if aid_li.count!=cart.count
        if aid_li.count>cart.count
          (aid_li.count-cart.count).times do
            aid_li.pop
          end
        elsif aid_li.count<cart.count
          (cart.count-aid_li.count).times do
            aid_li.push(aid_li.last)
          end
        end
      cookies[:aid_li] = {:value=>aid_li.join(":"), :path => "/",
        :expires => Settings.cart_cookie_days.to_i.days.from_now}
      cookies[:cart] = {:value=>cart.join(":"), :path => "/",
        :expires => Settings.cart_cookie_days.to_i.days.from_now}
      end
    end
  end

  def clear_cart
    cookies.delete(:cart)
    cookies.delete(:aid_li)
    current_user.shopping_cart.update_attribute(:content, nil) if current_user && current_user.shopping_cart
  end

  def identify_visitor
    cookies[:guid] = {:value=>UUIDTools::UUID.random_create.to_s, :path => "/",
      :expires => 2.years.from_now} unless cookies[:guid]
    @visitor_token = VisitorToken.find_or_create_by_guid_and_affiliate_id(
      cookies[:guid],cookies[:aid])
    @visitor_token.user ||= current_user if current_user
    @visitor_token.save if @visitor_token.changed? #TODO only if change
  end

  def record_visit
    return if request.method.downcase != "get"
    md5_current = Digest::MD5.hexdigest(request.url)
    if request.referer
      md5_previous = Digest::MD5.hexdigest(request.referer)
    end
    cur = TrackedUrl.find_or_create_by_md5_and_url(md5_current,request.url)
    prev = request.referer ? TrackedUrl.find_or_create_by_md5_and_url(md5_previous,request.referer) : nil
    Tracking.create(:referer=>prev,:visitor_token=>@visitor_token,
      :tracked_url=>cur, remote_ip: request.remote_ip)
#    output = cache(md5) { request.request_uri }
#    if @visitor
#      md5 = Digest::MD5.hexdigest(request.request_uri)
#      output = cache(md5) { request.request_uri }
#
#      @tracking = UUID.random_create
#      cookies[:guid] = {:value=>guid, :path => "/", :expires => 2.years.from_now} unless cookies[:guid]
#      @visitor_token = VisitorToken.find_or_build_by_guid(cookies[:guid])
#      @visitor_token.user ||= current_user if current_user
#      @visitor_token.affiliate_id = cookies[:aid] if cookies[:aid] && token.affiliate_id != cookies[:aid]
#      @visitor_token.save
#    end
  end

  #Surl related functions
  def add_link_to_cookie(guid)
    guids=get_guids
    guids << guid.to_s
    save_links_cookie({guid: guids.compact.join(","), v: Surl::COOKIE_VERSION})
  end

  def remove_link_from_cookie(guid)
    guids=get_guids
    unless guids.blank? || guids.include?(guid)
      guids.delete guid
    end
    save_links_cookie({guid: guids.compact.join(","), v: Surl::COOKIE_VERSION})
  end

  def get_valid_surls(page=nil)
    requested=get_guids
    guids=page.blank? ? Surl.where{guid >> requested} :
        Surl.where{guid >> requested}.paginate(page)
    unless guids.empty?
      (requested - guids.map(&:guid)).map do |g|
        remove_link_from_cookie(g)
      end
      guids.select{|surl|surl.status==Surl::REMOVE}.each do |g|
        remove_link_from_cookie(g)
      end
    end
    guids
  end

  def get_guids
    upgrade_cookie
    links=get_cookie("links2")
    guids=links.blank? ? [] : links["guid"].split(",")
  end

  #renaming cookie from links to links2
  def upgrade_cookie
    links=get_cookie(:links)
    unless links.blank?
      guids = links['guid']
      cookies.delete(:links)# if request.subdomains.last=="links"
      save_links_cookie({guid: guids, v: Surl::COOKIE_VERSION})
    end
  end

  def save_links_cookie(value)
    save_cookie name: Surl::COOKIE_NAME, value: value, path: "/",
                expires: 2.years.from_now, domain: ".ssl.com"
  end

  def record_surl_visit
    SurlVisit.create visitor_token: @visitor_token,
      surl: @surl,
      referer_host: request.env['REMOTE_HOST'],
      referer_address: request.env['REMOTE_ADDR'],
      request_uri: request.url,
      http_user_agent: request.env['HTTP_USER_AGENT'],
      result: @render_result
  end

  def record_order_visit(order)
    order.update_attribute :visitor_token, @visitor_token if @visitor_token
  end

  def assign_ssl_links(user)
    get_valid_surls.each do |surl|
      if surl.user.blank?
        user.surls<<surl
      end
    end
  end

  def is_iphone?
    return false if request.env['HTTP_USER_AGENT'].blank?
    ua = request.env['HTTP_USER_AGENT'].downcase
    ua =~ /iphone|itouch|ipod/
  end

  def is_client_windows?
    (request.env['HTTP_USER_AGENT'] =~ /windows/i)
  end

  %W(email login).each do |u|
    define_method("find_dup_#{u}") do
      is_new_session = params[:user_session]
      attr=is_new_session.blank? ? params[u.to_sym] : is_new_session[u.to_sym]
      @dup=DuplicateV2User.send("find_by_#{u}", attr) unless
          User.send("find_by_#{u}", attr)
      unless @dup.blank?
        flash.now[:error]="Ooops, #{u=="email" ? @dup.email : @dup.login} has been consolidated with a primary account.
          Please contact support@ssl.com for assistance or more information." unless request.xhr?
        if is_new_session
          DuplicateV2UserMailer.attempted_login_by(@dup).deliver
          @user_session = UserSession.new(:login=>is_new_session[u.to_sym])
        else
          DuplicateV2UserMailer.duplicates_found(@dup, u).deliver
        end
        respond_to do |format|
          format.html {render action: :new}
          #assume checkout
          format.js   {render :json=>@dup}
        end
      end
    end
  end

  def hide_dcv?
    @other_party_validation_request && @other_party_validation_request.hide_dcv?
  end

  def hide_documents?
    @other_party_validation_request && @other_party_validation_request.hide_documents?
  end

  def hide_both?
    @other_party_validation_request && @other_party_validation_request.hide_both?
  end

  def error(status, code, message)
    render :js => {:response_type => "ERROR", :response_code => code, :message => message}.to_json, :status => status
  end

  def team_base
    @ssl_account = SslAccount.where('ssl_slug = ? OR acct_number = ?', params[:ssl_slug], params[:ssl_slug]).first
    if current_user.get_all_approved_accounts.include?(@ssl_account)
      current_user.set_default_ssl_account(@ssl_account)
    end
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end
end
