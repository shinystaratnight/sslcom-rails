class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new
  end

  def create
    if params["prev.x".intern]
      #assume trying to login during checkout
      if params[:certificate_order]
        @certificate_order=CertificateOrder.new(params[:certificate_order])
        @certificate_order.has_csr=true
        render(:template => "/certificates/buy",
          :layout=>"application")
      else
        redirect_to show_cart_orders_url and return
      end
    end
    if !current_user.blank?
      if current_user.is_admin?
        @user_session = UserSession.new(User.find_by_login params[:login])
        @user_session.id = :shadow
        clear_cart
      else
        @user_session = current_user_session
      end
    else
      require_no_user
      @user_session = UserSession.new(params[:user_session])
    end
    respond_to do |format|
      if @user_session.save && !@user_session.user.is_disabled?
        user = @user_session.user
        #we'll know what tier the user is even if s/he is not logged in
        cookies.delete(:r_tier)
        if user.ssl_account.is_registered_reseller?
          cookies[:r_tier] = {:value=>user.ssl_account.reseller.
              reseller_tier.label, :path => "/", :expires => AppConfig.
              cart_cookie_days.to_i.days.from_now}
        end
        if user.duplicate_v2_users.empty?
          flash[:notice] = "Successfully logged in."
          format.html {redirect_back_or_default account_url}
          us_json = @user_session.to_json.chop << ',"redirect":"'+
            (user.ssl_account.is_registered_reseller?  ?
            allocate_funds_for_order_url('order') : new_order_url) +'"}'
          format.js   {render :json=>us_json}
        else
#          redirect and present choices of user names and emails (if dupes exist) (radios) then
#            delete the remaining dup_v2_users rename current username the new username
#          end
          #we'll know what tier the user is even if s/he is not logged in
          flash[:notice] = "Successfully logged in. Multiple usernames and/or
            email addresses were found for this account."
          format.html {redirect_to consolidate_user_url(user)}
          us_json = @user_session.to_json.chop << ',"redirect":"'+ 
            consolidate_user_url(user) +'"}'
          format.js   {render :json=>us_json}
        end
      elsif @user_session.attempted_record &&
        !@user_session.attempted_record.active?
        flash[:notice] = "Your account has not been activated. %s"
        flash[:notice_item] = "Click here to have the activation email
          resent to #{@user_session.attempted_record.email}.",
          resend_activation_users_path(:login => @user_session.attempted_record.login)
        @user_session.errors.add_to_base("please visit
          #{resend_activation_users_url(:login => @user_session.attempted_record.login)}
          to have your activation notice resent")
        format.html {render :action => :new}
        format.js   {render :json=>@user_session.errors}
      elsif !@user_session.user.blank? && @user_session.user.is_disabled?
        flash[:error] = "Account has been disabled"
        @user_session.destroy
        @user_session = UserSession.new
        format.html {render :action => :new}
        format.js   {render :json=>@user_session}
      else
        format.html {render :action => :new}
        format.js   {render :json=>@user_session.errors}
      end
    end
  end

  def destroy
    if current_user.is_admin?
      cookies.delete(:r_tier)
      clear_cart
    end
    current_user_session.destroy
    Authorization.current_user=nil
    flash[:notice] = "Successfully logged out."
    respond_to do |format|
      format.html {redirect_back_or_default new_user_session_url}
    end
  end
end