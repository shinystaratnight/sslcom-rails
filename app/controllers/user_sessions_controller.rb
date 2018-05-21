class UserSessionsController < ApplicationController
  before_filter :require_no_user, only: [:new]
  before_filter :find_dup_login, only: [:create]
  before_filter :require_user, only: :destroy
  skip_filter :finish_reseller_signup, only: [:destroy]
  skip_before_action :verify_authenticity_token
  skip_before_action :require_no_authentication, only: [:duo_verify]
  
  def new
    @user_session = UserSession.new
    session[:duo_auth] = false
  end

  def show
    if params[:login]
      create
    else
      redirect_to action: :new
    end
  end

  def user_login
    result_obj = {}
    key_handles = []

    @user_session = UserSession.new(params[:user_session])

    if @user_session.save && !@user_session.user.is_disabled?
      user = @user_session.user

      # cookies[:acct] = {
      #     :value=>user.ssl_account.acct_number,
      #     :path => "/",
      #     :expires => Settings.cart_cookie_days.to_i.days.from_now
      # }

      #we'll know what tier the user is even if s/he is not logged in
      cookies.delete(:r_tier)
      cookies[:cart] = {
          :value=>user.shopping_cart.content,
          :path => "/",
          :expires => Settings.cart_cookie_days.to_i.days.from_now
      } if user.shopping_cart

      if user.ssl_account.is_registered_reseller?
        cookies[:r_tier] = {
            :value=>user.ssl_account.reseller.reseller_tier.label,
            :path => "/",
            :expires => Settings.cart_cookie_days.to_i.days.from_now
        }
      end

      # Fetch existing U2Fs from your db
      key_handles = @user_session.user.u2fs.pluck(:key_handle)
      # @user_session.destroy
    end

    unless key_handles.empty?
      # Generate SignRequests
      result_obj['app_id'] = u2f.app_id
      result_obj['sign_requests'] = u2f.authentication_requests(key_handles)
      result_obj['challenge'] = u2f.challenge

      # Store challenge. We need it for the verification step
      session[:challenge] = result_obj['challenge']
    end

    render :json => result_obj
  end

  def create
    if params["prev.x".intern]
      #assume trying to login during checkout
      if params[:certificate_order]
        @certificate_order=CertificateOrder.new(params[:certificate_order])
        @certificate_order.has_csr=true
        if params["prev.x".intern]
          render(:template => "/certificates/buy",
                 :layout=>"application")
        end
      else
        redirect_to show_cart_orders_url and return
      end
    end

    if current_user.blank?
      @user_session = UserSession.new(params[:user_session])
    else
      if current_user.is_admin? && params[:login]
        @user_session = UserSession.new(User.find_by_login params[:login])
        @user_session.id = :shadow
        clear_cart
      end

      unless current_user.ssl_account.nil?
        cookies[:acct] = {
          value: current_user.ssl_account.acct_number,
          path: "/",
          expires: Settings.cart_cookie_days.to_i.days.from_now
        }
      end
    end

    respond_to do |format|
      if @user_session
        if @user_session.save && !@user_session.user.is_disabled?
          user = @user_session.user

          cookies[:acct] = {
              :value=>user.ssl_account.acct_number,
              :path => "/",
              :expires => Settings.cart_cookie_days.to_i.days.from_now
          }

          #we'll know what tier the user is even if s/he is not logged in
          cookies.delete(:r_tier)
          cookies[:cart] = {
              :value=>user.shopping_cart.content,
              :path => "/",
              :expires => Settings.cart_cookie_days.to_i.days.from_now
          } if user.shopping_cart

          if user.ssl_account.is_registered_reseller?
            cookies[:r_tier] = {
                :value=>user.ssl_account.reseller.reseller_tier.label,
                :path => "/",
                :expires => Settings.cart_cookie_days.to_i.days.from_now
            }
          end

          flash[:notice] = "Successfully logged in." unless request.xhr?
          format.js   {render :json=>url_for_js(user)}
          format.html {redirect_back_or_default account_path(user.ssl_account(:default_team) ?
                                                                 user.ssl_account(:default_team).to_slug :
                                                                 {})}
        elsif @user_session.attempted_record && !@user_session.attempted_record.active?
          flash[:notice] = "Your account has not been activated. %s"
          flash[:notice_item] = "Click here to have the activation email resent to #{@user_session.attempted_record.email}.",
              resend_activation_users_path(:login => @user_session.attempted_record.login)
          @user_session.errors[:base] << ("please visit #{resend_activation_users_url(
              :login => @user_session.attempted_record.login)} to have your activation notice resent")

          log_failed_attempt(@user_session.user, params,flash[:notice])
          format.html {render :action => :new}
          format.js   {render :json=>@user_session.errors}
        elsif @user_session.user.blank? || (!@user_session.user.blank? && @user_session.user.is_admin_disabled?)
          unless @user_session.user.blank?
            if (!@user_session.user.blank? && @user_session.user.is_admin_disabled?)
              flash.now[:error] = "Ooops, it appears this account has been disabled." unless request.xhr?

              log_failed_attempt(@user_session.user, params,flash.now[:error])
              @user_session.destroy
              @user_session=UserSession.new
            end
          end
          log_failed_attempt(@user_session.user, params,@user_session.errors.to_json)
          format.html {render :action => :new}
          format.js   {render :json=>@user_session}
        else
          log_failed_attempt(params[:user_session][:login], params,flash.now[:error])
          format.html {render :action => :new}
          format.js   {render :json=>@user_session.errors}
        end
      else
        if params[:logout] == 'true'
          if current_user.is_admin?
            cookies.delete(:r_tier)
            cookies.delete(:cart_guid)
            clear_cart
          end
          cookies.delete(:acct)
          current_user_session.destroy
          Authorization.current_user=nil
          flash[:error] = "Unable to sign with U2F." unless params[:user]

          @user_session = UserSession.new(params[:user_session])

          format.html {render :action => :new}
          format.js   {render :json=>@user_session}
        else
          @user_session = current_user_session

          # TODO: Check U2F
          if params['u2f_response'].blank?
            if current_user.ssl_account(:default_team).duo_enabled
              flash[:notice] = "2 Step Verification." unless request.xhr?
            else
              flash[:notice] = "Successfully logged in." unless request.xhr?
            end
            format.js   {render :json=>url_for_js(current_user)}
            if current_user.ssl_account(:default_team).duo_enabled
              format.html {redirect_to(duo_user_session_url)}
            else
              session[:duo_auth] = true
              format.html {redirect_back_or_default account_path(current_user.ssl_account(:default_team) ? current_user.ssl_account(:default_team).to_slug : {})}
            end
          else
            # if current_user.is_admin?
            #   cookies.delete(:r_tier)
            #   cookies.delete(:cart_guid)
            #   clear_cart
            # end
            # cookies.delete(:acct)
            # current_user_session.destroy
            # Authorization.current_user=nil
            # flash[:error] = "Unable to authenticate with U2F: "
            #
            # @user_session = UserSession.new(params[:user_session])
            # format.html {render :action => :new}
            # format.js   {render :json=>@user_session}

            response = U2F::SignResponse.load_from_json(params[:u2f_response])
            reg_u2f = current_user.u2fs.find_by_key_handle(response.key_handle) if response.key_handle

            unless reg_u2f
              flash[:notice] = "Successfully logged in." unless request.xhr?

              format.js   {render :json=>url_for_js(current_user)}
              format.html {redirect_back_or_default account_path(current_user.ssl_account(:default_team) ?
                                                                     current_user.ssl_account(:default_team).to_slug :
                                                                     {})}
            end

            begin
              u2f.authenticate!(
                  session[:challenge],
                  response,
                  Base64.decode64(reg_u2f.public_key),
                  reg_u2f.counter
              )

              reg_u2f.update(counter: response.counter)
            rescue U2F::Error => e
              # Log out to protect hack.
              if current_user.is_admin?
                cookies.delete(:r_tier)
                cookies.delete(:cart_guid)
                clear_cart
              end
              cookies.delete(:acct)
              current_user_session.destroy
              Authorization.current_user=nil
              flash[:error] = "Unable to authenticate with U2F: " + e.class.name unless params[:user]

              @user_session = UserSession.new(params[:user_session])
              format.html {render :action => :new}
              format.js   {render :json=>@user_session.errors}
            ensure
              session.delete(:challenge)
            end

            flash[:notice] = "Successfully logged in." unless request.xhr?

            format.js   {render :json=>url_for_js(current_user)}
            format.html {redirect_back_or_default account_path(current_user.ssl_account(:default_team) ?
                                                                   current_user.ssl_account(:default_team).to_slug :
                                                                   {})}
          end
        end
      end
    end
  end

#   def create
#     if params["prev.x".intern]
#       #assume trying to login during checkout
#       if params[:certificate_order]
#         @certificate_order=CertificateOrder.new(params[:certificate_order])
#         @certificate_order.has_csr=true
#         if params["prev.x".intern]
#           render(:template => "/certificates/buy",
#             :layout=>"application")
#         end
#       else
#         redirect_to show_cart_orders_url and return
#       end
#     end
#     unless current_user.blank?
#       if current_user.is_admin?
#         @user_session = UserSession.new(User.find_by_login params[:login])
#         @user_session.id = :shadow
#         clear_cart
#       else
#         @user_session = current_user_session
#       end
#       unless current_user.ssl_account.nil?
#         cookies[:acct] = {
#           value:   current_user.ssl_account.acct_number, path: "/",
#           expires: Settings.cart_cookie_days.to_i.days.from_now
#         }
#       end
#     else
#       require_no_user
#       @user_session = UserSession.new(params[:user_session])
#     end
#     respond_to do |format|
#       if @user_session.save && !@user_session.user.is_disabled?
#         user = @user_session.user
#         cookies[:acct] = {:value=>user.ssl_account.acct_number, :path => "/", :expires => Settings.
#             cart_cookie_days.to_i.days.from_now}
#         #we'll know what tier the user is even if s/he is not logged in
#         cookies.delete(:r_tier)
#         cookies[:cart] = {:value=>user.shopping_cart.content, :path => "/",
#                           :expires => Settings.cart_cookie_days.to_i.days.from_now} if user.shopping_cart
#         if user.ssl_account.is_registered_reseller?
#           cookies[:r_tier] = {:value=>user.ssl_account.reseller.
#             reseller_tier.label, :path => "/", :expires => Settings.
#             cart_cookie_days.to_i.days.from_now}
#         end
#         flash[:notice] = "Successfully logged in." unless request.xhr?
#         format.js   {render :json=>url_for_js(user)}
#         format.html {redirect_back_or_default account_path(user.ssl_account(:default_team) ? user.ssl_account(:default_team).to_slug : {})}
# #        us_json = @user_session.to_json.chop << ',"redirect":"'+
# #          (user.ssl_account.is_registered_reseller?  ?
# #          "create" : new_order_url) +'"}'
#
#
# #        else
# #          redirect and present choices of user names and emails (if dupes exist) (radios) then
# #            delete the remaining dup_v2_users rename current username the new username
# #          end
#           #we'll know what tier the user is even if s/he is not logged in
# #          flash[:notice] = "Successfully logged in. Multiple usernames and/or
# #            email addresses were found for this account."
# #          format.html {redirect_to consolidate_user_url(user)}
# #          us_json = @user_session.to_json.chop << ',"redirect":"'+
# #            consolidate_user_url(user) +'"}'
# #          format.js   {render :json=>us_json}
# #        end
#       elsif @user_session.attempted_record &&
#         !@user_session.attempted_record.active?
#         flash[:notice] = "Your account has not been activated. %s"
#         flash[:notice_item] = "Click here to have the activation email
#           resent to #{@user_session.attempted_record.email}.",
#           resend_activation_users_path(:login => @user_session.attempted_record.login)
#         @user_session.errors[:base]<<("please visit
#           #{resend_activation_users_url(:login => @user_session.attempted_record.login)}
#           to have your activation notice resent")
#         log_failed_attempt(@user_session.user, params,flash[:notice])
#         format.html {render :action => :new}
#         format.js   {render :json=>@user_session.errors}
#       elsif @user_session.user.blank? || (!@user_session.user.blank? && @user_session.user.is_admin_disabled?)
#         unless @user_session.user.blank?
#           if (!@user_session.user.blank? && @user_session.user.is_admin_disabled?)
#             flash.now[:error] = "Ooops, it appears this account has been disabled." unless request.xhr?
#             log_failed_attempt(@user_session.user, params,flash.now[:error])
#             @user_session.destroy
#             @user_session=UserSession.new
#           end
#         end
#         log_failed_attempt(@user_session.user, params,@user_session.errors.to_json)
#         format.html {render :action => :new}
#         format.js   {render :json=>@user_session}
#       else
#         log_failed_attempt(params[:user_session][:login], params,flash.now[:error])
#         format.html {render :action => :new}
#         format.js   {render :json=>@user_session.errors}
#       end
#     end
#   end

  def duo
    if current_user.ssl_account(:default_team).duo_own_used
      @duo_account = current_user.ssl_account(:default_team).duo_account
      @duo_hostname = @duo_account.duo_hostname
      @sig_request = Duo.sign_request(@duo_account ? @duo_account.duo_ikey : "", @duo_account ? @duo_account.duo_skey : "", @duo_account ? @duo_account.duo_akey : "", current_user.login)
    else
      s = Rails.application.secrets;
      @duo_hostname = s.duo_hostname
      @sig_request = Duo.sign_request(s.duo_ikey, s.duo_skey, s.duo_akey, current_user.login)
    end
  end

  def duo_verify
    if current_user.ssl_account(:default_team).duo_own_used
      @duo_account = current_user.ssl_account(:default_team).duo_account
      @authenticated_user = Duo.verify_response(@duo_account ? @duo_account.duo_ikey : "", @duo_account ? @duo_account.duo_skey : "", @duo_account ? @duo_account.duo_akey : "", params['sig_response'])
    else
      s = Rails.application.secrets;
      @authenticated_user = Duo.verify_response(s.duo_ikey, s.duo_skey, s.duo_akey, params['sig_response'])
    end
    if @authenticated_user
      session[:duo_auth] = true
      respond_to do |format|
        format.js   {render :json=>url_for_js(current_user)}
        format.html {redirect_to account_path(current_user.ssl_account(:default_team) ? current_user.ssl_account(:default_team).to_slug : {})}
      end
    else
      redirect_to action: :new
    end
  end

  def destroy
    if current_user.is_admin?
      cookies.delete(:r_tier)
      cookies.delete(:cart_guid)
      clear_cart
    end
    cookies.delete(:acct)
    current_user_session.destroy
    Authorization.current_user=nil
    flash[:notice] = "Successfully logged out."
    respond_to do |format|
      format.html {redirect_to new_user_session_url}
    end
  end

private

  def url_for_js(user)
    redirect = create_ssl_certificate_route(user)
    @user_session.to_json.chop << ',"redirect_method":"'+redirect[0]+
      '","url":"'+redirect[1]+'"'+
        (user.ssl_account.billing_profiles.empty? ? '' :
        ',"billing_profiles":'+render_to_string(partial: '/orders/billing_profiles',
        locals: {ssl_account: user.ssl_account }).to_json)+'}'
  end

  def log_failed_attempt(user, params, reason)
    SystemAudit.create(
      if user
        {owner:  user,
         target: nil,
         action: "Failed login attempt by #{user.login} from ip address #{request.remote_ip}",
         notes:  reason}
      else
        {owner:  nil,
        target: nil,
        action: "Failed login attempt by #{params[:user_session][:login]} from ip address #{request.remote_ip}",
        notes:  reason}
    end)
  end
end
