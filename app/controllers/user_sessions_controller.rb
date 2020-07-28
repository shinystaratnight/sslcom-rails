class UserSessionsController < ApplicationController
  before_action :require_no_user, only: [:new]
  before_action :find_dup_login, only: [:create]
  before_action :require_user, only: %i[destroy duo]
  skip_before_action :finish_reseller_signup, only: [:destroy]
  skip_before_action :verify_authenticity_token
  skip_before_action :verify_duo_authentication, only: %i[new create destroy]
  skip_before_action :verify_u2f_authentication, only: %i[new create destroy duo duo_verify]
  skip_before_action :require_no_authentication, only: [:duo_verify]
  skip_before_action :use_2fa_authentication
  before_action :check_recaptcha, only: %i[user_login create]

  def new
    @user_session = UserSession.new
    # Keep the count when page refreshes
    session[:failed_count] ||= 0
    session[:duo_auth] = false
    session[:authenticated] = false
  end

  def show
    if login_param
      create
    else
      redirect_to action: :new
    end
  end

  def user_login
    @result_obj = {}
    key_handles = []
    cart_and_u2fs = lambda {
      @user_session = UserSession.new(params[:user_session].to_h)
      @user = User.find_by(login: @user_session.login)

      if @user && @user_session.valid? && !@user.is_disabled?
        # Fetch existing U2Fs from your db
        key_handles = @user.u2fs.pluck(:key_handle)
      end
    }

    cart_and_u2fs.call

    unless key_handles.empty?
      # Generate SignRequests
      @result_obj['app_id'] = u2f.app_id
      @result_obj['sign_requests'] = u2f.authentication_requests(key_handles)
      @result_obj['challenge'] = u2f.challenge

      # Store challenge. We need it for the verification step
      session[:challenge] = @result_obj['challenge']
    end
    session[:authenticated] = false

    @result_obj['failed_count'] = session[:failed_count].to_i
    render json: @result_obj
  end

  def create
    # Not sure if/when we enter the following block
    if params["prev.x".intern]
      # assume trying to login during checkout
      if params[:certificate_order]
        @certificate_order = CertificateOrder.new(params[:certificate_order])
        @certificate_order.has_csr = true
        render(template: 'certificat_orders/submit_csr', layout: 'application') if params['prev.x'.intern]
      else
        redirect_to(show_cart_orders_url) && return
      end
    end

    if current_user.blank?
      @user_session = UserSession.new(params[:user_session].to_h)
    else
      if current_user.is_admin? && login_param
        @user_session = UserSession.new((User.find_by login: login_param))
        @user_session.id = :shadow
        clear_cart
      end

      set_cookie(:acct, current_user.ssl_account.acct_number) unless current_user&.ssl_account&.nil?
    end

    respond_to do |format|
      @failed_count = session[:failed_count].to_i

      if @user_session
        if @user_session.save && !@user_session.user.is_disabled?
          user = shopping_cart_to_cookie

          session[:authenticated] = false
          session[:pre_authenticated_user_id] = @user_session.user.id

          flash[:notice] = 'Successfully logged in.' unless request.xhr?

          set_authentication

          format.js   { render json: url_for_js(user) }
          format.html do
            set_redirect(user: user)
          end

        elsif @user_session.attempted_record && !@user_session.attempted_record.active?
          flash[:notice] = 'Your account has not been activated. %s'
          flash[:notice_item] = "Click here to have the activation email resent to #{@user_session.attempted_record.email}.",
                                resend_activation_users_path(login: @user_session.attempted_record.login)
          @user_session.errors[:base] << "please visit #{resend_activation_users_url(
            login: @user_session.attempted_record.login
          )} to have your activation notice resent"

          log_failed_attempt(@user_session.user, params, flash[:notice])
          format.html { render action: :new }
          format.js   { render json: @user_session.errors }
        elsif @user_session.user.blank? || (@user_session.user.present? && @user_session.user.is_admin_disabled?)
          # This is also the case for wrong password
          session[:failed_count] += 1
          if @user_session.user.present?
            if @user_session.user.present? && @user_session.user.is_admin_disabled?
              flash.now[:error] = 'Ooops, it appears this account has been disabled.' unless request.xhr?

              log_failed_attempt(@user_session.user, params, flash.now[:error])
              @user_session.destroy
              @user_session = UserSession.new
            end
          end
          log_failed_attempt(@user_session.user, params, @user_session.errors.to_json)
          format.html { render action: :new }
          format.js   { render json: @user_session }
        else
          session[:failed_count] += 1
          log_failed_attempt(params[:user_session][:login], params, flash.now[:error])
          format.html { render action: :new }
          format.js   { render json: @user_session.errors }
        end
      end

      current_user ||= @user_session&.user || current_user_session&.user
      if !session[:authenticated] && current_user.present?
        if params[:logout] == 'true'
          if current_user.is_admin?
            cookies.delete(ResellerTier::TIER_KEY)
            cookies.delete(ShoppingCart::CART_GUID_KEY)
            clear_cart
          end
          cookies.delete(:acct)
          current_user_session.destroy
          Authorization.current_user = nil
          # flash[:error] = 'Unable to sign with U2F.' unless params[:user]

          @user_session = UserSession.new(params[:user_session].to_h)

          format.html { render action: :new }
          format.js   { render json: @user_session }
        else
          @user_session = current_user_session

          if current_user.is_duo_required?
            flash[:notice] = 'Duo 2-factor authentication setup.' unless request.xhr?
            format.js   { render json: url_for_js(current_user) }
            format.html { redirect_to(duo_user_session_url) }
          else
            if current_user_default_team&.sec_type == 'duo'
              if current_user_default_team.duo_enabled && (Settings.duo_auto_enabled || Settings.duo_custom_enabled) && current_user.duo_enabled
                flash[:notice] = 'Duo 2-factor authentication setup.' unless request.xhr?
              else
                flash[:notice] = 'Successfully logged in.' unless request.xhr?
              end
              format.js { render json: url_for_js(current_user) }
              if current_user_default_team.duo_enabled && (Settings.duo_auto_enabled || Settings.duo_custom_enabled) && current_user.duo_enabled
                format.html { redirect_to(duo_user_session_url) }
              else
                session[:duo_auth] = true
                format.html { redirect_back_or_default account_path(current_user_default_team ? current_user_default_team.to_slug : {}) }
              end
            # Access to teams that have u2f enabled is handled in use_2fa_authentication
            # What we should care about here is whether or not users have added 2fa for their account (regardless of any team requirement)
            elsif current_user_default_team&.sec_type == 'u2f' || current_user.u2fs.any?
              redirect_to new_u2f_path and return
            else
              session[:duo_auth] = true
              flash[:notice] = 'Successfully logged in.' unless request.xhr?
              format.js   { render json: url_for_js(current_user) }
              format.html { redirect_back_or_default account_path(current_user_default_team ? current_user_default_team.to_slug : {}) }
            end
          end
        end
      end
    end
  end

  def duo
    return if current_user.blank?
    if current_user.is_duo_required?
      s = Rails.application.secrets
      @duo_hostname = s.duo_system_admins_api_hostname
      @sig_request = Duo.sign_request(s.duo_system_admins_integration_key, s.duo_system_admins_secret_key, s.duo_system_admins_application_key, current_user.login)
    else
      if Settings.duo_auto_enabled && Settings.duo_custom_enabled
        if current_user.ssl_account(:default_team).duo_own_used
          @duo_account = current_user.ssl_account(:default_team).duo_account
          @duo_hostname = @duo_account.duo_hostname
          @sig_request = Duo.sign_request(@duo_account ? @duo_account.duo_ikey : "", @duo_account ? @duo_account.duo_skey : "", @duo_account ? @duo_account.duo_akey : "", current_user.login)
        else
          s = Rails.application.secrets
          @duo_hostname = s.duo_api_hostname
          @sig_request = Duo.sign_request(s.duo_integration_key, s.duo_secret_key, s.duo_application_key, current_user.login)
        end
      elsif Settings.duo_auto_enabled && !Settings.duo_custom_enabled
        s = Rails.application.secrets
        @duo_hostname = s.duo_api_hostname
        @sig_request = Duo.sign_request(s.duo_integration_key, s.duo_secret_key, s.duo_application_key, current_user.login)
      else
        @duo_account = current_user.ssl_account(:default_team).duo_account
        @duo_hostname = @duo_account ? @duo_account.duo_hostname : ""
        @sig_request = Duo.sign_request(@duo_account ? @duo_account.duo_ikey : "", @duo_account ? @duo_account.duo_skey : "", @duo_account ? @duo_account.duo_akey : "", current_user.login)
      end
    end
  end

  def duo_verify
    if current_user.is_duo_required?
      s = Rails.application.secrets;
      @authenticated_user = Duo.verify_response(s.duo_system_admins_integration_key, s.duo_system_admins_secret_key, s.duo_system_admins_application_key, params['sig_response'])
    else
      if Settings.duo_auto_enabled && Settings.duo_custom_enabled
        if current_user.ssl_account(:default_team).duo_own_used
          @duo_account = current_user.ssl_account(:default_team).duo_account
          @authenticated_user = Duo.verify_response(@duo_account ? @duo_account.duo_ikey : "", @duo_account ? @duo_account.duo_skey : "", @duo_account ? @duo_account.duo_akey : "", params['sig_response'])
        else
          s = Rails.application.secrets;
          @authenticated_user = Duo.verify_response(s.duo_integration_key, s.duo_secret_key, s.duo_application_key, params['sig_response'])
        end
      elsif Settings.duo_auto_enabled && !Settings.duo_custom_enabled
        s = Rails.application.secrets;
        @authenticated_user = Duo.verify_response(s.duo_integration_key, s.duo_secret_key, s.duo_application_key, params['sig_response'])
      else
        @duo_account = current_user.ssl_account(:default_team).duo_account
        @authenticated_user = Duo.verify_response(@duo_account ? @duo_account.duo_ikey : "", @duo_account ? @duo_account.duo_skey : "", @duo_account ? @duo_account.duo_akey : "", params['sig_response'])
      end
    end if current_user

    if @authenticated_user
      session[:duo_auth] = true
      session[:authenticated] = true
      respond_to do |format|
        format.js   {render :json=>url_for_js(current_user)}
        format.html {redirect_back_or_default account_path(current_user.ssl_account(:default_team) ? current_user.ssl_account(:default_team).to_slug : {})}
      end
    else
      redirect_to action: :new
    end
  end

  def destroy
    # Keep u2f authentication if this was user shadowing
    unless current_user_session.id == :shadow
      session[:pre_authenticated_user_id] = nil
      session[:authenticated] = false
    end

    if current_user.is_admin?
      cookies.delete(ResellerTier::TIER_KEY)
      cookies.delete(ShoppingCart::CART_GUID_KEY)
      clear_cart
    end
    cookies.delete(:acct)
    current_user_session.destroy
    Authorization.current_user = nil

    session[:request_referrer] = nil
    flash[:notice] = 'Successfully logged out.'
    session[:failed_count] = 0
    session[:u2f_failed_count] = 0
    respond_to do |format|
      format.html {
        redirect_path = if current_user_session.id == :shadow
                          account_path
                        else
                          new_user_session_url
                        end
        redirect_to redirect_path
      }
    end
  end

  private

  def shopping_cart_to_cookie
    user = @user_session.user
    set_cookie(:acct, user.ssl_account.acct_number)
    # we'll know what tier the user is even if s/he is not logged in
    cookies.delete(ResellerTier::TIER_KEY)

    if user.shopping_cart
      if cookies[ShoppingCart::CART_KEY].blank?
        set_cookie(ShoppingCart::CART_KEY, user.shopping_cart.content)
      else
        if cookies[ShoppingCart::CART_GUID_KEY].present? && cookies[ShoppingCart::CART_GUID_KEY] == user.shopping_cart.guid
          set_cookie(ShoppingCart::CART_KEY, cookies[ShoppingCart::CART_KEY])
        else
          content = user.shopping_cart.content.blank? ? [] : JSON.parse(user.shopping_cart.content)
          content = shopping_cart_content(content, JSON.parse(cookies[ShoppingCart::CART_KEY]))
          user.shopping_cart.update_attribute :content, content
          set_cookie(ShoppingCart::CART_KEY, content)
        end
      end
    end
    set_cookie(ResellerTier::TIER_KEY, user.ssl_account.reseller.reseller_tier.label) if user.ssl_account.is_registered_reseller?
    user
  end

  def url_for_js(user)
    redirect = create_ssl_certificate_route(user)
    @user_session.to_json.chop << ',"redirect_method":"' + redirect[0] +
                                  '","url":"' + redirect[1] + '"' +
                                  (user.ssl_account.billing_profiles.empty? ? '' :
                                  ',"billing_profiles":' + render_to_string(partial: '/orders/billing_profiles',
                                                                            locals: { ssl_account: user.ssl_account }).to_json) + '}'
  end

  def log_failed_attempt(user, params, reason)
    SystemAudit.create(
      if user
        { owner: user,
          target: nil,
          action: "Failed login attempt by #{user.login} from ip address #{request.remote_ip}",
          notes: reason }
      else
        { owner: nil,
          target: nil,
          action: "Failed login attempt by #{params[:user_session] ? params[:user_session][:login] : login_param} from ip address #{request.remote_ip}",
          notes: reason }
      end
    )
  end

  def shopping_cart_content(content, cart)
    cart.each_with_index do |i_cart, _i|
      idx = -1

      content.each_with_index do |j_content, j|
        match = true
        i_cart.keys.each do |key|
          if key != ShoppingCart::QUANTITY && key != ShoppingCart::AFFILIATE && i_cart[key] != j_content[key]
            match = false
            break
          end
        end

        if match
          idx = j
          break
        end
      end

      if idx == -1
        if content.is_a?(Array)
          content << i_cart
        else
          content = [i_cart]
        end
      else
        content[idx][ShoppingCart::QUANTITY] = content[idx][ShoppingCart::QUANTITY].to_i + i_cart[ShoppingCart::QUANTITY].to_i
      end
    end

    content.to_json
  end

  ##
  # Verifies captcha before proceeding to login process
  def check_recaptcha
    return unless session[:failed_count].to_i >= Settings.captcha_threshold.to_i

    unless verify_recaptcha(response: params[:user_session]['g-recaptcha-response'])
      @user_session = UserSession.new(params[:user_session].to_h)
      session[:failed_count] += 1
      flash.now[:error] = 'Recaptcha failed!'
      render :new and return
    end
  end

  def set_authentication
    session[:authenticated] = true
    session[:authenticated] = false if @user_session.user.is_duo_required?
    session[:authenticated] = false if @user_session.user.u2fs.any?
    # u2f authentication is true by default for user being shadowed
    session[:authenticated] = true if @user_session.id == :shadow
  end

  def duo_api_host_name
    Rails.application.secrets.duo_api_hostname
  end

  def duo_integration_key
    Rails.application.secrets.duo_integration_key
  end

  def duo_secret_key
    Rails.application.secrets.duo_secret_key
  end

  def duo_application_key
    Rails.application.secrets.duo_application_key
  end

  def duo_system_admins_integration_key
    Rails.application.secrets.duo_system_admins_integration_key
  end

  def duo_system_admins_secret_key
    Rails.application.secrets.duo_system_admins_secret_key
  end

  def duo_system_admins_application_key
    Rails.application.secrets.duo_system_admins_application_key
  end

  def sig_response_param
    params['sig_response']
  end

  def login_param
    params[:login]
  end
end
