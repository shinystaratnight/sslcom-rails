# frozen_string_literal: true

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_auth_token
  layout 'application'
  include ApplicationHelper
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::RoutingError, with: :not_found
  rescue_from AbstractController::ActionNotFound, with: :not_found
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  helper_method :current_user_session, :current_user, :is_reseller, :cookies, :current_website,
                :cart_contents, :cart_products, :certificates_from_cookie, 'is_iphone?', 'hide_dcv?', :free_qty_limit,
                'hide_documents?', 'hide_both?', 'hide_validation?'
  before_action :set_database, if: 'request.host=~/^sandbox/ || request.host=~/^sws-test/'
  before_action :set_mailer_host
  before_action :detect_recert, except: %i[renew reprocess]
  before_action :set_current_user
  before_action :verify_duo_authentication, except: %i[duo duo_verify login logout], if: -> { skip_duo_cookie.nil? }
  before_action :identify_visitor, :record_visit,
                if: 'Settings.track_visitors'
  before_action :finish_reseller_signup, if: 'current_user'
  before_action :team_base, if: 'params[:ssl_slug] && current_user'
  before_action :set_ssl_slug, :load_notifications
  after_action :set_access_control_headers # need to move parse_csr to api, if: "request.subdomain=='sws' || request.subdomain=='sws-test'"

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*' if Rails.env.development? # nginx handles this in production
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def permission_denied
    if current_user
      flash[:error] = 'You currently do not have permission to access that page.'
      redirect_to account_path
    else
      store_location
      flash[:notice] = 'You must be logged in to access this page'
      redirect_to new_user_session_path
      false
    end
  end

  def paginated_scope(relation)
    instance_variable_set "@#{controller_name}", relation.paginate(params[:page])
  end

  def is_reseller?
    current_user&.ssl_account&.is_registered_reseller?
  end

  def save_user
    @user.create_ssl_account([Role.get_owner_id])
    @user.signup!(params)
    @user.activate!(params)

    # Check Code Signing Certificate Order for assign as assignee.
    CertificateOrder.unscoped.search_validated_not_assigned(@user.email).each do |cert_order|
      cert_order.update_attribute(:assignee, @user)
      LockedRecipient.create_for_co(cert_order)
    end

    @user.deliver_activation_confirmation!
    @user_session = UserSession.create(@user)
    @current_user_session = @user_session
    Authorization.current_user = @current_user = @user_session.record
  end

  def verify_duo_authentication
    if skip_duo_cookie.nil?
      if current_user
        if current_user.is_duo_required?
          redirect_to duo_user_session_path unless session[:duo_auth]
        else
          if current_user&.ssl_account&.sec_type == 'duo' && current_user.duo_enabled
            if Settings.duo_auto_enabled || Settings.duo_custom_enabled
              redirect_to duo_user_session_path unless session[:duo_auth]
            end
          end
        end
      end
    end
  end

  def skip_duo_cookie
    return nil unless Rails.env.test?

    cookies['skip_duo']
  end

  def find_tier
    @tier ||= if @certificate_order
                @certificate_order&.tier_suffix
              elsif current_user&.tier_suffix
                current_user.tier_suffix
              elsif reseller_tier_cookie
                ResellerTier.tier_suffix(reseller_tier_cookie)
              elsif id = params[:reseller_id]
                Reseller.find(id)&.ssl_account&.tier_suffix
              end
  end

  def add_to_cart(line_item)
    session[:cart_items] << line_item.model_and_id
  end

  def apply_discounts(order)
    if params[:discount_code]
      order.temp_discounts = []
      general_discount = Discount.viable.general.find_by(ref: params[:discount_code])
      if current_user && !current_user.is_system_admins?
        if current_user.ssl_account.discounts.find_by(ref: params[:discount_code])
          order.temp_discounts << current_user.ssl_account.discounts.find_by(ref: params[:discount_code]).id
        elsif general_discount
          order.temp_discounts << general_discount.id
        end
      elsif general_discount
        order.temp_discounts << general_discount.id
      end
    end
  end

  # check to see if the cart cookie should be blanked
  def delete_cart_cookie?
    if cookies[ShoppingCart::CART_KEY] == 'delete'
      cookies.delete(ShoppingCart::CART_KEY, domain: :all)
      return true
    end
    false
  end

  # returns the cart cookie with reseller tier as an array
  def cart_contents
    find_tier
    delete_cart_cookie?
    cart = cookies[ShoppingCart::CART_KEY]
    cart.blank? ? {} :
        JSON.parse(cart).each{ |i| i['pr'] = i['pr'] + @tier if i && @tier && i['pr'] && !i['pr'].ends_with?(@tier) }
  end

  def cart_products
    cart_contents.collect do |cart_item|
      pr = cart_item[ShoppingCart::PRODUCT_CODE]
      if pr.blank?
        nil
      else
        ApplicationRecord.find_from_model_and_id(pr)
      end
    end.compact
  end

  def delete_cart_items
    cookies.delete ShoppingCart::CART_KEY, domain: cookie_domain
  end

  def save_cart_items(items)
    set_cookie(ShoppingCart::CART_KEY, JSON.generate(items))
  end

  def free_qty_limit
    qty = current_user ?
        Certificate::FREE_CERTS_CART_LIMIT - current_user.ssl_account.cached_certificate_orders.unused_free_credits.count :
        Certificate::FREE_CERTS_CART_LIMIT
    qty <= 0 ? 0 : qty
  end

  # parse the cookie and build @certificate_orders
  def certificates_from_cookie
    certs = cart_contents
    @certificate_orders = []
    return @certificate_orders if certs.blank?

    limit = free_qty_limit
    Order.certificates_order(certificates: certs, max_free: limit,
                             certificate_orders: @certificate_orders, current: current_user)
  end

  def old_certificates_from_cookie
    @certificate_orders = []
    return @certificate_orders unless cookies[ShoppingCart::CART_KEY]

    Order.cart_items session, cookies
    certs = cookies[ShoppingCart::CART_KEY].split(':')
    certs.each do |c|
      parts = c.split(',')
      certificate_order = CertificateOrder.new server_licenses: parts[2],
                                               duration: parts[1], quantity: parts[4].to_i
      certificate_order.certificate_contents.build domains: parts[3]
      certificate = Certificate.for_sale.find_by(product: parts[0])
      if current_user.present?
        current_user.ssl_account.clear_new_certificate_orders
        next unless current_user.ssl_account.can_buy?(certificate)
      end
      # adjusting duration to reflect number of days validity
      duration = certificate.duration_in_days(certificate_order.duration)
      certificate_order.certificate_contents[0].duration = duration
      if certificate.is_ucc? || certificate.is_wildcard?
        psl = certificate.items_by_server_licenses.find do |item|
          item.value == duration.to_s
        end
        so = SubOrderItem.new(product_variant_item: psl,
                              quantity: certificate_order.server_licenses.to_i,
                              amount: psl.amount * certificate_order.server_licenses.to_i)
        certificate_order.sub_order_items << so
        if certificate.is_ucc?
          pd = certificate.items_by_domains.find_all do |item|
            item.value == duration.to_s
          end
          additional_domains = (certificate_order.domains.try(:size) || 0) - Certificate::UCC_INITIAL_DOMAINS_BLOCK
          so = SubOrderItem.new(product_variant_item: pd[0],
                                quantity: Certificate::UCC_INITIAL_DOMAINS_BLOCK,
                                amount: pd[0].amount * Certificate::UCC_INITIAL_DOMAINS_BLOCK)
          certificate_order.sub_order_items << so
          if additional_domains.positive?
            so = SubOrderItem.new(product_variant_item: pd[1],
                                  quantity: additional_domains,
                                  amount: pd[1].amount * additional_domains)
            certificate_order.sub_order_items << so
          end
        end
      end
      unless certificate.is_ucc?
        pvi = certificate.items_by_duration.find{ |item| item.value == duration.to_s }
        so = SubOrderItem.new(product_variant_item: pvi, quantity: 1,
                              amount: pvi.amount)
        certificate_order.sub_order_items << so
      end
      certificate_order.amount = certificate_order.sub_order_items.map(&:amount).sum
      certificate_order.certificate_contents[0]
                       .certificate_order = certificate_order
      @certificate_orders << certificate_order if certificate_order.valid?
    end
  end

  def find_certificate
    prod = params[:id] == 'mssl' ? 'high_assurance' : params[:id]
    @certificate = Certificate.includes(:product_variant_items).for_sale.find_by(product: prod + (@tier || ''))
  end

  def find_certificate_orders(options = {})
    return CertificateOrder.none unless current_user # returns null set. Rails 4 is CertificateOrder.none

    @search = params[:search] || ''
    @search << ' is_test:true' if is_sandbox? && @search.include?('is_test:true').blank?

    result = if @search.present?
               (current_user.is_admin? ?
                    (CertificateOrder.unscoped do
                      (@ssl_account.try(:cached_certificate_orders) || CertificateOrder).search_with_csr(params[:search], options)
                    end) :
                    (current_user.role_symbols(current_user.ssl_account) == [Role::INDIVIDUAL_CERTIFICATE.to_sym] ?
                          current_user.ssl_account.cached_certificate_orders.search_assigned(current_user.id).search_with_csr(params[:search], options) :
                          current_user.ssl_account.cached_certificate_orders.search_with_csr(params[:search], options)
                    )
               )
             else
               (current_user.is_admin? ?
                    (@ssl_account.try(:cached_certificate_orders) || CertificateOrder).not_test.not_new(options) :
                    (current_user.role_symbols(current_user.ssl_account) == [Role::INDIVIDUAL_CERTIFICATE.to_sym] ?
                          current_user.ssl_account.cached_certificate_orders.not_test.not_new(options).search_assigned(current_user.id) :
                          current_user.ssl_account.cached_certificate_orders.not_test.not_new(options)
                    )
               )
             end.order(params[:order] == 'by_csr' ? 'csrs.created_at desc' : 'certificate_orders.created_at desc')
    result = result.joins{ certificate_contents.csr } if params[:order] == 'by_csr'
    if options[:source] && options[:source] == 'folders'
      archived_folder = current_user.is_admin? || params[:search]&.include?('folder_ids') ?
                            [true, false, nil] : [false, nil]
      result = result.includes(:folder).where(folders: { archived: archived_folder })
    end
    result
  end

  def find_certificate_orders_with_site_seals
    return CertificateOrder.where('1=0') unless current_user # returns null set. Rails 4 is CertificateOrder.none

    if (@search = params[:search])
      (current_user.is_admin? ?
        CertificateOrder.search_with_csr(params[:search]) :
        current_user.certificate_orders
          .search_with_csr(params[:search])).has_csr
    else
      (current_user.is_admin? ?
        CertificateOrder.not_new(include: :site_seal) :
        current_user.certificate_orders.not_new(include: :site_seal))
    end
  end

  def set_cookie(name, value)
    # cookies.delete(name, domain: "secure.ssl.local") if name==:cart
    cookies[name] = { value: value, path: '/', domain: :all,
                      expires: Settings.cart_cookie_days.to_i.days.from_now }
  end

  def set_ssl_slug(target_user = nil)
    user = target_user || current_user
    if user
      ssl = user.ssl_account
      @ssl_slug = if user.is_system_admins?
                    nil
                  else
                    ssl.ssl_slug || ssl.acct_number if ssl
                  end
    end
    guest_enrollment if user.nil?
  end

  def not_found
    render 'site/404_not_found', status: :not_found
  end

  protected

  def guest_enrollment
    @ssl_slug = params[:ssl_slug] if %w[enrollment_links].include? action_name
  end

  def set_prev_flag
    @prev = true if params['prev.x'.intern]
  end

  def prep_certificate_orders_instances
    if params[:certificate_order]
      @certificate = Certificate.for_sale.find_by(product: params[:certificate][:product])
      co_valid = certificate_order_steps
      if params["prev.x".intern] || !co_valid
        @certificate_order.has_csr=true
        render(template: "submit_csr", layout: "application")
        return false
      end
    else
      unless params['prev.x'.intern].nil?
        redirect_to(show_cart_orders_url) && return
        return false
      end
      certificates_from_cookie
    end
  end

  def set_current_user
    Authorization.current_user = current_user
    if current_user && current_user.ssl_accounts.blank?
      current_user_session.destroy
      Authorization.current_user = nil
      false
    end
  end

  def setup_orders
    # will create @certificate_orders below
    certificates_from_cookie
    @order = Order.new(amount: (current_order.amount.to_s.to_i || 0))
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
    # need to create new objects and delete the existing ones
    @certificate_order = current_user.ssl_account
                                     .certificate_orders.detect(&:new?)
    @certificate = @certificate_order.certificate
    @certificate_content = @certificate_order.certificate_content.dup
    @certificate_order = current_user.ssl_account
                                     .certificate_orders.detect(&:new?).dup
    @certificate_order.duration = @certificate.duration_index(@certificate_content.duration)
    @certificate_order.has_csr = true
    render(template: "submit_csr", layout: "application")
  end

  def create_ssl_certificate_route(user)
    if user.ssl_account.is_registered_reseller?
      ['submit', params[:certificate] ? certificate_orders_url : new_order_url]
    else
      if params[:certificate] && params[:certificate][:product]
        # assume a single cert sale
        params[:certificate][:product] == 'free' ? ['submit', ''] : ['', '']
      else
        # shopping cart checkout
        shopping_cart_amount.positive? ? ['', ''] : ['submit', '']
      end
    end
  end

  def shopping_cart_amount
    certificates_from_cookie.sum(&:amount)
  end

  # co - certificate order
  def hide_validation?(co)
    if current_user.blank?
      true
    else
      !co.certificate_content.show_validation_view?
    end
  end

  #   def responder
  #     EnhancedResponder
  #   end

  def handle_unverified_request
    # or destroy session, redirect
    current_user_session&.destroy
    redirect_to root_url
    # raise an exception
    raise ActionController::InvalidAuthenticityToken
  end

  def invalid_auth_token
    render text: "Invalid authentication token. Please restart session or go to #{root_url} to start a new session.", status: :unprocessable_entity
  end

  # derive the model name from the controller. egs UsersController will return User
  def self.permission
    self.name = begin
                  name.gsub('Controller', '').singularize.split('::').last.constantize.name
                rescue StandardError
                  nil
                end
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # load the permissions for the current user so that UI can be manipulated
  def load_permissions
    @current_permissions = current_user.permissions.collect{ |i| [i.subject_class, i.action] }
  end

  def find_ssl_account
    ssl_acct_slug = params[:ssl_slug] || params[:acct_number] ||
                    (params[:certificate_enrollment_request][:ssl_slug] if params[:certificate_enrollment_request])
    if (params[:action] == 'dcv_all_validate') && ssl_acct_slug
      @ssl_account = SslAccount.where('ssl_slug = ? OR acct_number = ?', ssl_acct_slug, ssl_acct_slug).last
      not_found if @ssl_account.blank?
    elsif current_user.blank?
      not_found
    else
      @ssl_account = if ssl_acct_slug && (request[:action] != 'validate_ssl_slug')
                       ssls = current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts
                       ssls.where('ssl_slug = ? OR acct_number = ?', ssl_acct_slug, ssl_acct_slug).last
                     else
                       current_user.ssl_account
                     end
      not_found if @ssl_account.blank?
    end
  end

  def load_notifications
    if current_user
      if current_user.pending_account_invites?
        @team_invites = []
        current_user.get_pending_accounts.each do |invite|
          new_params       = { ssl_account_id: invite[:ssl_account_id], token: invite[:approval_token], to_teams: true }
          invite[:accept]  = approve_account_invite_user_path(current_user, new_params)
          invite[:decline] = decline_account_invite_user_path(current_user, new_params)
          invite.delete(:approval_token)
          @team_invites << invite
        end
      end
      flash[:info_activation] = true if current_user.persist_notice && current_user.assignments.where.not(role_id: Role.cannot_be_invited)
    end
  end

  def u2f
    @u2f ||= U2F::U2F.new(request.base_url)
  end

  def current_user_default_team
    current_user&.ssl_account(:default_team)
  end

  def rails_application_secrets
    @rails_application_secrets ||= Rails.application.secrets
  end

  private

  def reseller_tier_cookie
    cookies[ResellerTier::TIER_KEY]
  end

  def get_team_tags
    @team_tags ||= if @taggable
                     Tag.get_object_team_tags(@taggable)
                   elsif current_user.is_system_admins?
                     Tag.all.order(taggings_count: :desc)
                   elsif @ssl_account || ssl_account
                     (@ssl_account || ssl_account).tags.order(name: :asc)
                   else
                     []
                   end
  end

  # Saves a cookie using a hash
  # <tt>options</tt> - Contains keys name, value (a hash), path, and expires
  def save_cookie(options)
    c = { value: JSON.generate(options[:value]), path: options[:path],
          expires: options[:expires] }
    c[:domain] = options[:domain] if options[:domain]
    cookies[options[:name]] = c
  end

  def get_cookie(name)
    name = name.to_sym if name.is_a? String
    cookies[name].blank? ? {} : JSON.parse(cookies[name])
  end

  # if in process of recerting (renewal, reprocess, etc), this sets instance
  # variables from params. Only one type allowed at a time.
  def detect_recert
    CertificateOrder::RECERTS.each do |r|
      next if params[r.to_sym].blank?

      recert = CertificateOrder.find_by(ref: params[r.to_sym])
      instance_variable_set("@#{r.to_sym}", recert) if recert
      break
    end
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)

    @current_user_session = UserSession.find(:shadow).try(:user) ? UserSession.find(:shadow) : UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = current_user_session&.user
  end

  def require_user
    if current_user.blank?
      store_location
      flash[:notice] = 'You must be logged in to access this page'
      redirect_to new_user_session_path
      false
    end
  end

  def global_set_row_page
    klass, row_count, page_size = case params[:controller]
                                  when 'domains'
                                    params[:action] == 'select_csr' ? [Domain, 'preferred_domain_csr_row_count', 'per_page']
                                        : [Domain, 'preferred_domain_row_count', 'per_page']
                                  when 'scan_logs'
                                    [ScanLog, 'preferred_scan_log_row_count', 'per_page']
                                  when 'managed_csrs'
                                    [Csr, 'preferred_managed_csr_row_count', 'per_page']
                                  when 'orders'
                                    [Order, 'preferred_order_row_count', 'per_page']
                                  when 'cdns'
                                    [Cdn, 'preferred_cdn_row_count', 'per_page']
                                  when 'certificate_orders'
                                    [CertificateOrder, 'preferred_cert_order_row_count', 'per_page']
                                  when 'notification_groups'
                                    [NotificationGroup, 'preferred_note_group_row_count', 'per_page']
                                  when 'users'
                                    params[:action] == 'teams' ? [SslAccount, 'preferred_team_row_count', 'per_page']
                                        : [User, 'preferred_user_row_count', 'per_page']
                                  when 'registered_agents'
                                    %w[index search].include?(params[:action]) ? [RegisteredAgent, 'preferred_registered_agent_row_count', 'ra_per_page']
                                        : [ManagedCertificate, 'preferred_managed_certificate_row_count', 'mc_per_page']
                                  end

    preferred_row_count = current_user.try(row_count)
    @per_page = params[page_size.to_sym] || preferred_row_count.or_else('10')
    klass.per_page = @per_page if klass.per_page != @per_page

    current_user.update_attribute(row_count, @per_page) if @per_page != preferred_row_count

    @p = { page: (params[:page] || 1), per_page: @per_page }
  end

  def require_admin
    user_not_authorized unless current_user.is_admin?
  end

  def require_no_user
    if current_user
      store_location
      set_cookie(:acct, current_user.ssl_account.acct_number)
      flash[:notice] = "You must be logged out to access page '#{request.fullpath}'"
      redirect_to account_url
      false
    end
  end

  def go_prev
    unless params['prev.x'.intern].nil?
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
    go_to = session[:return_to] == logout_path ? nil : session[:return_to]
    session[:return_to] = nil
    redirect_to(go_to || default)
  end

  def finish_reseller_signup
    blocked = %w[certificate_orders orders site_seals validations ssl_accounts users]
    if current_user.is_reseller? && current_user.ssl_account.is_new_reseller?
      redirect_to(new_account_reseller_url) && return if
          (current_user.ssl_account.reseller ?
              # following line avoids loop with last condition in ResellersController#new comparing reseller.complete?
              # with ssl_account.is_new_reseller?
              !current_user.ssl_account.reseller.complete? :
              current_user.ssl_account.is_new_reseller?) && blocked.include?(controller_name)
    end
  end

  def user_not_authorized
    render 'site/403_forbidden', status: :forbidden
  end

  def save_billing_profile
    profile = current_user.ssl_account.billing_profiles.find_by card_number: @billing_profile.card_number
    current_user.ssl_account.billing_profiles.delete profile unless profile.nil?
    current_user.ssl_account.billing_profiles << @billing_profile
  end

  # this is a band-aid function to make sure the number of item in cookies
  # aid_li and cart match. however, the problem causing the unsync was found.
  # this function can be turned back on by the Settings.sync_aid_li_and_cart
  # variable
  def sync_aid_li_and_cart
    if cookies[ShoppingCart::AID_LI] && cookies[ShoppingCart::CART_KEY]
      aid_li = cookies[ShoppingCart::AID_LI].split(':')
      cart = cart_contents
      if aid_li.count != cart.count
        if aid_li.count > cart.count
          (aid_li.count - cart.count).times do
            aid_li.pop
          end
        elsif aid_li.count < cart.count
          (cart.count - aid_li.count).times do
            aid_li.push(aid_li.last)
          end
        end
        set_cookie(ShoppingCart::AID_LI, aid_li.join(':'))
        set_cookie(ShoppingCart::CART_KEY, cart.join(':'))
      end
    end
  end

  def clear_cart
    cookies.delete(ShoppingCart::CART_KEY, domain: cookie_domain)
    cookies.delete(ShoppingCart::AID_LI)
    current_user.shopping_cart.update_attribute(:content, nil) if current_user&.shopping_cart
  end

  def validation_destination(options)
    co = options[:certificate_order]
    slug = options[:ssl_slug]
    co.certificate.is_code_signing? ?
        document_upload_certificate_order_validation_url(certificate_order_id: co.ref) :
        new_certificate_order_validation_path(*[slug, co.ref].compact)
  end

  def identify_visitor
    unless cookies[VisitorToken::GUID]
      cookies[VisitorToken::GUID] = { value: UUIDTools::UUID.random_create.to_s, path: '/',
                                      expires: 2.years.from_now }
    end
    @visitor_token = VisitorToken.find_or_create_by_guid_and_affiliate_id(
      cookies[VisitorToken::GUID], cookies[ShoppingCart::AID]
    )
    @visitor_token.user ||= current_user if current_user
    @visitor_token.save if @visitor_token.changed? # TODO: only if change
  end

  def record_visit
    return unless request.method.casecmp('get').zero?

    md5_current = Digest::MD5.hexdigest(request.url)
    md5_previous = Digest::MD5.hexdigest(request.referer) if request.referer
    cur = TrackedUrl.find_or_create_by_md5_and_url(md5_current, request.url)
    prev = request.referer ? TrackedUrl.find_or_create_by_md5_and_url(md5_previous, request.referer) : nil
    Tracking.create(referer: prev, visitor_token: @visitor_token,
                    tracked_url: cur, remote_ip: request.remote_ip)
    #    output = cache(md5) { request.request_uri }
    #    if @visitor
    #      md5 = Digest::MD5.hexdigest(request.request_uri)
    #      output = cache(md5) { request.request_uri }
    #
    #      @tracking = UUID.random_create
    #      cookies[VisitorToken::GUID] = {:value=>guid, :path => "/", :expires => 2.years.from_now} unless cookies[VisitorToken::GUID]
    #      @visitor_token = VisitorToken.find_or_build_by_guid(cookies[VisitorToken::GUID])
    #      @visitor_token.user ||= current_user if current_user
    #      @visitor_token.affiliate_id = cookies[ShoppingCart::AID] if cookies[ShoppingCart::AID] && token.affiliate_id != cookies[ShoppingCart::AID]
    #      @visitor_token.save
    #    end
  end

  # Surl related functions
  def add_link_to_cookie(guid)
    guids = get_guids
    guids << guid.to_s
    save_links_cookie(guid: guids.compact.join(','), v: Surl::COOKIE_VERSION)
  end

  def remove_link_from_cookie(guid)
    guids = get_guids
    guids.delete guid unless guids.blank? || guids.include?(guid)
    save_links_cookie(guid: guids.compact.join(','), v: Surl::COOKIE_VERSION)
  end

  def get_valid_surls(page = nil)
    requested = get_guids
    guids = page.blank? ? Surl.where{ guid >> requested } :
        Surl.where{ guid >> requested }.paginate(page)
    unless guids.empty?
      (requested - guids.map(&:guid)).map do |g|
        remove_link_from_cookie(g)
      end
      guids.select{ |surl| surl.status == Surl::REMOVE }.each do |g|
        remove_link_from_cookie(g)
      end
    end
    guids
  end

  def get_guids
    upgrade_cookie
    links = get_cookie('links2')
    guids = links.blank? ? [] : links['guid'].split(',')
    guids
  end

  # renaming cookie from links to links2
  def upgrade_cookie
    links = get_cookie(:links)
    if links.present?
      guids = links['guid']
      cookies.delete(:links) # if request.subdomains.last=="links"
      save_links_cookie(guid: guids, v: Surl::COOKIE_VERSION)
    end
  end

  def save_links_cookie(value)
    save_cookie name: Surl::COOKIE_NAME, value: value, path: '/',
                expires: 2.years.from_now, domain: '.ssl.com'
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
      user.surls << surl if surl.user.blank?
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

  %w[email login].each do |u|
    define_method("find_dup_#{u}") do
      is_new_session = params[:user_session]
      attr = is_new_session.blank? ? params[u.to_sym] : is_new_session[u.to_sym]
      @dup = DuplicateV2User.send("find_by_#{u}", attr) unless
          User.send("find_by_#{u}", attr)
      if @dup.present?
        unless request.xhr?
          flash.now[:error] = "Ooops, #{u == 'email' ? @dup.email : @dup.login} has been consolidated with a primary account.
            Please contact support@ssl.com for assistance or more information."
        end
        if is_new_session
          DuplicateV2UserMailer.attempted_login_by(@dup).deliver
          @user_session = UserSession.new(login: is_new_session[u.to_sym].to_h)
        else
          DuplicateV2UserMailer.duplicates_found(@dup, u).deliver
        end
        respond_to do |format|
          format.html { render action: :new }
          # assume checkout
          format.js   { render json: @dup }
        end
      end
    end
  end

  def hide_dcv?
    @other_party_validation_request&.hide_dcv?
  end

  def hide_documents?
    @other_party_validation_request&.hide_documents?
  end

  def hide_both?
    @other_party_validation_request&.hide_both?
  end

  def error(status, code, message)
    render js: { response_type: 'ERROR', response_code: code, message: message }.to_json, status: status
  end

  def team_base
    @ssl_account = SslAccount.where('ssl_slug = ? OR acct_number = ?', params[:ssl_slug], params[:ssl_slug]).first
    current_user.set_default_ssl_account(@ssl_account) unless current_user.is_system_admins? || !current_user.get_all_approved_accounts.include?(@ssl_account)
  end

  def is_sandbox_or_test?
    host = ActionMailer::Base.default_url_options[:host]
    (sandbox = (request && request.try(:subdomain) == 'sandbox')) || Sandbox.current_site(request.host).present?
    sandbox || host =~ /^sandbox\./ || host =~ /^sws-test\./
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end
end
