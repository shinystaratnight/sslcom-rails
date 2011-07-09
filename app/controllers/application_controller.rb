# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  layout 'application'
  #include Authentication
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found
  rescue_from ActionController::RoutingError, :with => :not_found
  rescue_from ActionController::UnknownAction, :with => :not_found
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :current_user_session, :current_user, :is_reseller, :cookies,
    :cart_contents, :cart_products, :certificates_from_cookie, "is_iphone?"
  before_filter :detect_recert, except: [:renew, :reprocess]
  before_filter :set_current_user
  before_filter :identify_visitor, :record_visit, :except=>[:refer]

#  hide_action :paginated_scope

  def permission_denied
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url :subdomain=>Settings.root_subdomain
      return false
    else
      flash[:error] = "You currently do not have permission to access that page."
      redirect_to root_url :subdomain=>Settings.root_subdomain
    end
  end

  def paginated_scope(relation)
    instance_variable_set "@#{controller_name}", relation.paginate(params[:page])
  end

  def is_reseller?
    current_user && current_user.ssl_account.is_registered_reseller?
  end

  def add_to_cart line_item
    session[:cart_items] << line_item.model_and_id
  end

  def cart_contents
    cart = cookies[:cart]
    cart.blank? ? {} : JSON.parse(cookies[:cart])
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

  def setup_certificate_order(certificate, certificate_order)
    duration = certificate.duration_in_days(certificate_order.duration)
    certificate_order.certificate_content.duration = duration
    if certificate.is_ucc? || certificate.is_wildcard?
      psl = certificate.items_by_server_licenses.find { |item|
        item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>psl,
       :quantity            =>certificate_order.server_licenses.to_i,
       :amount              =>psl.amount*certificate_order.server_licenses.to_i)
      certificate_order.sub_order_items << so
      if certificate.is_ucc?
        pd                 = certificate.items_by_domains.find_all { |item|
          item.value==duration.to_s }
        additional_domains = (certificate_order.certificate_contents[0].
            domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
        so                 = SubOrderItem.new(:product_variant_item=>pd[0],
                                              :quantity            =>Certificate::UCC_INITIAL_DOMAINS_BLOCK,
                                              :amount              =>pd[0].amount*Certificate::UCC_INITIAL_DOMAINS_BLOCK)
        certificate_order.sub_order_items << so
        if additional_domains > 0
          so = SubOrderItem.new(:product_variant_item=>pd[1],
                                :quantity            =>additional_domains,
                                :amount              =>pd[1].amount*additional_domains)
          certificate_order.sub_order_items << so
        end
      end
    end
    unless certificate.is_ucc?
      pvi = certificate.items_by_duration.find { |item| item.value==duration.to_s }
      so  = SubOrderItem.new(:product_variant_item=>pvi, :quantity=>1,
                             :amount              =>pvi.amount)
      certificate_order.sub_order_items << so
    end
    certificate_order.amount = certificate_order.
        sub_order_items.map(&:amount).sum
    certificate_order.certificate_contents[0].
        certificate_order    = certificate_order
    certificate_order
  end

  #see old_certificates_from_cookie for previous version
  def certificates_from_cookie
    certs=cart_contents
    @certificate_orders=[]
    return @certificate_orders if certs.blank?
    certs.each do |c|
      next if c[ShoppingCart::PRODUCT_CODE]=~/^reseller_tier/
      certificate_order = CertificateOrder.new(
        :server_licenses=>c[ShoppingCart::LICENSES],
        :duration=>c[ShoppingCart::DURATION],
        :quantity=>c[ShoppingCart::QUANTITY].to_i)
      certificate_order.add_renewal c[ShoppingCart::RENEWAL_ORDER]
      certificate_order.certificate_contents.build :domains=>
        c[ShoppingCart::DOMAINS]
      certificate = Certificate.find_by_product(c[ShoppingCart::PRODUCT_CODE])
      unless current_user.blank?
        current_user.ssl_account.clear_new_certificate_orders
        certificate_order.ssl_account=current_user.ssl_account
        next unless current_user.ssl_account.can_buy?(certificate)
      end
      #adjusting duration to reflect number of days validity
      certificate_order = setup_certificate_order(certificate, certificate_order)
      @certificate_orders << certificate_order if certificate_order.valid?
    end
    @certificate_orders
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
      certificate = Certificate.find_by_product(parts[0])
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
          additional_domains = (certificate_order.certificate_contents[0].
            domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
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

  def build_certificate_contents(certificate_orders, order)
    certificate_orders.each do |cert|
      cert.quantity.times do |i|
        new_cert = CertificateOrder.new(cert.attributes)
        cert.sub_order_items.each {|soi|
          new_cert.sub_order_items << SubOrderItem.new(soi.attributes)
        }
        cert.certificate_contents.each {|cc|
          cc_tmp = CertificateContent.new(cc.attributes)
          cc_tmp.certificate_order = new_cert
          new_cert.certificate_contents << cc_tmp
        }
        new_cert.line_item_qty = cert.quantity if(i==cert.quantity-1)
        new_cert.preferred_payment_order = 'prepaid'
        #the line blow was concocted because a simple assignment resulted in
        #the certificate_order coming up nil on each certificate_content
        #and failing the has_csr validation in the certificate_order
#        new_cert.certificate_contents.clear
#        cert.certificate_contents.each {|cc|
#          cc_tmp = cc.dclone
#          cc_tmp.certificate_order = new_cert
#          new_cert.certificate_contents << cc_tmp} unless cert.certificate_contents.blank?
        order.line_items.build :sellable=>new_cert
      end
    end
  end

  def find_certificate_orders(options={})
    if @search = params[:search]
      #options.delete(:page) if options[:page].nil?
      (current_user.is_admin? ?
        (CertificateOrder.search(params[:search], options)+
          Csr.search(params[:search]).map(&:certificate_orders).flatten) :
        current_user.ssl_account.certificate_orders.
          search_with_csr(params[:search], options)).select{|co|
        ['paid'].include? co.workflow_state}
    else
      (current_user.is_admin? ?
        CertificateOrder.find_not_new(options) :
        current_user.ssl_account.certificate_orders.not_new(options))
    end
  end

  #this function should be cronned and moved to a more appropriate location
  def self.flag_expired_certificate_orders
    Authorization.ignore_access_control(true)
    CertificateOrder.all(:include=>{:certificate_contents=>
          {:csr=>:signed_certificates}}).each {|co|
      expired =
        ['paid'].include?(co.workflow_state) &&
        co.created_at < Settings.cert_expiration_threshold_days.to_i.days.ago &&
        (co.certificate_content.csr.nil? ||
        co.certificate_content.csr.try(:signed_certificate).nil?)
      co.update_attribute :is_expired, expired
    }
  end

  def find_certificate_orders_with_site_seals
    if @search = params[:search]
      (current_user.is_admin? ?
        (CertificateOrder.search(params[:search])+
          Csr.search(params[:search]).map(&:certificate_orders).flatten) :
        current_user.ssl_account.certificate_orders.
          search_with_csr(params[:search])).select{|co|
        ['paid'].include? co.workflow_state}
    else
      (current_user.is_admin? ?
        CertificateOrder.find_not_new(:include=>:site_seal) :
        current_user.ssl_account.certificate_orders.not_new(:include=>:site_seal))
    end
  end

  protected

  def set_prev_flag
    @prev=true if params["prev.x".intern]
  end

  def prep_certificate_orders_instances
    if params[:certificate_order]
      @certificate = Certificate.find_by_product(params[:certificate][:product])
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
  end

  def setup_certificate_orders
    #will create @certificate_orders below
    certificates_from_cookie
    @order = Order.new(:amount=>(current_order.amount.to_s.to_i or 0))
    build_certificate_contents(@certificate_orders, @order)
  end

  def parse_certificate_orders
    if params[:certificate_order]
      @certificate_order = current_user.ssl_account.certificate_orders.current
      @order = current_order
    else
      setup_certificate_orders
    end
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

=begin
  def responder
    EnhancedResponder
  end
=end

  private

  #Saves a cookie using a hash
  # <tt>options</tt> - Contains keys name, value (a hash), path, and expires
  def save_cookie(options)
    cookies[options[:name]] = {:value=>JSON.generate(options[:value]), :path => options[:path],
      :expires => options[:expires]}
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
    @current_user_session = UserSession.find(:shadow) || UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
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
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    go_to = (session[:return_to] == logout_path) ? nil : session[:return_to]
    session[:return_to] = nil
    redirect_to(go_to || default)
  end

  def finish_reseller_signup
    redirect_to new_account_reseller_url and return if
      current_user.ssl_account.has_role?('new_reseller')
  end

  def user_not_authorized
    render :text => "403 Forbidden", :status => 403
  end

  def not_found
    render :text => "404 Not Found", :status => 404
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
  end

  def identify_visitor
    cookies[:guid] = {:value=>UUIDTools::UUID.random_create, :path => "/",
      :expires => 2.years.from_now} unless cookies[:guid]
    @visitor_token = VisitorToken.find_or_create_by_guid_and_affiliate_id(
      cookies[:guid],cookies[:aid])
    @visitor_token.user ||= current_user if current_user
    @visitor_token.save if @visitor_token.changed? #TODO only if change
  end

  def record_visit
    return if request.method.downcase != "get"
    md5_current = Digest::MD5.hexdigest(request.url)
    md5_previous = Digest::MD5.hexdigest(request.referer) if request.referer
    cur = TrackedUrl.find_or_create_by_md5_and_url(md5_current,request.url)
    prev = TrackedUrl.find_or_create_by_md5_and_url(md5_previous,request.referer)
    Tracking.create(:referer=>prev,:visitor_token=>@visitor_token,
      :tracked_url=>cur)
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
    save_cookie name: :links, value: {guid: guids.compact.join(",")}, path: "/", expires: 2.years.from_now
  end

  def remove_link_from_cookie(guid)
    guids=get_guids
    unless guids.blank? || guids.include?(guid)
      guids.delete guid
    end
    save_cookie name: :links, value: {guid: guids.compact.join(",")}, path: "/", expires: 2.years.from_now
  end

  def get_valid_surls
    guids=get_guids
    unless guids.blank?
      guids.map do |g|
        surl=Surl.find_by_guid(g)
        if surl.blank? || surl.status==Surl::REMOVE
          remove_link_from_cookie(g)
          nil
        else
          surl
        end
      end.compact
    else
      guids
    end
  end

  def get_guids
    links=get_cookie("links")
    guids=links.blank? ? [] : links["guid"].split(",")
  end

  def record_surl_visit
    SurlVisit.create visitor_token: @visitor_token,
                    surl: @surl,
                    referer_host: request.env['REMOTE_HOST'],
                    referer_address: request.env['REMOTE_ADDR'],
                    request_uri: request.env['REQUEST_URI'],
                    http_user_agent: request.env['HTTP_USER_AGENT'],
                    result: @render_result
  end

  def assign_ssl_links(user)
    get_valid_surls.each do |surl|
      user.surls<<surl if surl.user.blank?
    end
  end

  def is_iphone?
    ua = request.env['HTTP_USER_AGENT'].downcase
    ua =~ /iphone|itouch|ipod/
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end
end
