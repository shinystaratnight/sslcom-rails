class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, only: [
    :show, :edit, :update, :cancel_reseller_signup, 
    :approve_account_invite, :resend_account_invite,
    :switch_default_ssl_account, :enable_disable
  ]
  before_filter :finish_reseller_signup, :only => [:show]
  before_filter :new_user, :only=>[:create, :new]
  before_filter :find_user, :set_admin_flag, :only=>[:edit_email,
    :edit_password, :update, :login_as, :admin_update, :admin_show,
    :consolidate, :dup_info, :adjust_funds, :change_login, 
    :switch_default_ssl_account, :enable_disable]
 # before_filter :index, :only=>:search
  filter_access_to  :all
  filter_access_to  :update, :admin_update, :enable_disable,
    :switch_default_ssl_account, :decline_account_invite,
    :approve_account_invite, attribute_check: true
  filter_access_to  :consolidate, :dup_info, :require=>:update
  filter_access_to  :resend_activation, :activation_notice, :require=>:create
  filter_access_to  :edit_password, :edit_email, :cancel_reseller_signup, :require=>:edit

  def new
  end

  def new_affiliate
    render action: "new"
  end

  def search
    index
  end

  def index
    p = {:page => params[:page]}
    set_users

    if params[:search]
      search = params[:search].strip.split(" ")
      role = nil
      search.delete_if {|s|s =~ /role\:(.+)/; role ||= $1; $1}
      search = search.join(" ")
      @users = @users.with_role(role) if role
      @users = @users.search(search) unless search.blank?
    end
    @users = @users.order("created_at desc").paginate(p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @users }
    end
  end

  def create
    reseller = request.subdomain == Reseller::SUBDOMAIN
    if @user.signup!(params)
      @user.create_ssl_account
      if reseller
        @user.ssl_account.add_role! "new_reseller"
        @user.ssl_account.set_reseller_default_prefs
      end
      @user.set_roles_for_account(
        @user.ssl_account,
        [Role.find_by_name((reseller ? Role::RESELLER : Role::ACCOUNT_ADMIN)).id]
      )
      @user.deliver_activation_instructions!
      notice = "Your account has been created. Please check your
        e-mail at #{@user.email} for your account activation instructions!"
      flash[:notice] = notice
      #in production heroku, requests coming FROM a subdomain will not transmit
      #flash messages to the target page. works fine in dev though
      redirect_to(request.subdomain == Reseller::SUBDOMAIN ? login_url(:notice => notice) : login_url)
    else
      render :action => :new
    end
  end

  def show
    if current_user.ssl_account.has_credits?
      flash.now[:warning] = "You have unused ssl certificate credits. %s"
      flash.now[:warning_item] = "Click here to view the list of credits.",
        credits_certificate_orders_path
    end
    if current_user.pending_account_invites?
      render_invite_messages
    end
  end

  def cancel_reseller_signup
    if current_user.role_symbols.include? Role::RESELLER.to_sym
      current_user.ssl_account.remove_role! "new_reseller"
      current_user.ssl_account.reseller.destroy unless current_user.ssl_account.reseller.blank?
      current_user.roles.delete Role.find_by_name(Role::RESELLER)
    end
    current_user.roles << Role.find_by_name(Role::ACCOUNT_ADMIN) unless current_user.role_symbols.include?(Role::ACCOUNT_ADMIN.to_sym)
    flash[:notice] = "reseller signup has been canceled"
    @user = current_user #for rable object reference
  end

  def admin_show
  end

  def edit
  end

  def login_as
  end

  def dup_info
  end

  def adjust_funds
    amount=params["amount"].to_f*100
    @user.ssl_account.funded_account.add_cents(amount)
    SystemAudit.create(owner: current_user, target: @user.ssl_account.funded_account,
                       notes: "amount (in USD): #{amount.to_s}",
                       action: "FundedAccount#add_cents")
    redirect_to admin_show_user_path(@user)
  end

  def change_login
    old = @user.login
    @user.login = params["login"]
    if(@user.valid?)
      User.change_login old, params["login"]
      SystemAudit.create(owner: current_user, target: @user,
                         notes: "changed login from #{old} to #{params["login"]}",
                         action: "UserController#change_login")
    else
      @user.login = old
    end
    render action: :admin_show
  end

  def consolidate
    login, email = params[:login], params[:email]
    keep_login = (@user.login == login)
    keep_email = (@user.email == email)
    if keep_login && keep_email
      #delete all duplicate_v2_users
    elsif email && login && !(keep_login && keep_email)
      #change both
    elsif email
      #change email
    elsif login
      #change login
    end
    change_password
  end

  def edit_password
    @user ||= @current_user
    permission_denied if (!@current_user.is_admin? && @current_user != @user)
    @chpwd = (admin_op?)? false : true
  end

  def edit_email
    @user ||= @current_user
    permission_denied unless admin_or_current_user?
  end

  def update
    @user ||= @current_user # makes our views "cleaner" and more consistent
    edit_email = (params[:edit_action] == 'edit_email')? true : false
    unless edit_email
      @user.changing_password = true #nonelegant hack to trigger validations of password
      @user.errors[:base]<<(
        'Old password value does not match password to be changed') unless
        @user.valid_password?(params[:old_password]) unless admin_op?
    end
    old_address=@user.email #be sure to notify where changed from
    if @user.errors.empty? && @user.update_attributes(params[:user])
      flash[:notice] = "Account updated."
      unless edit_email
        @user.deliver_password_changed!
      else
        @user.deliver_email_changed!(old_address)
        @user.deliver_email_changed!
      end
      redirect_to admin_op? ? users_url : edit_account_url
    elsif edit_email
      render :action => :edit_email
    else
      @chpwd = true
      render :action => :edit_password
    end
  end

  def admin_update
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.js { render :json=>@user.to_json}
      else
        format.js { render :json=>@user.errors.to_json}
      end
    end
  end

  def resend_activation
    if params[:login]
      @user = User.find_by_login params[:login]
      if @user
        if !@user.active?
          @user.deliver_activation_instructions!
          flash[:notice] = "Account activation instructions are on it's way - please check your e-mail for further instructions"
        else
          flash[:notice] = "Looks like user #{params[:login]} has already been activated"
        end
      else
        if DuplicateV2User.find_by_login params[:login]
          flash[:notice] = "Ooops, looks like user #{params[:login]} has been consolidated with another account.
            Please contact support@ssl.com for more details"
        else
          flash[:notice] = "Ooops, looks like user #{params[:login]} doesn't exist in our system"
        end
      end
      redirect_to login_path
    end
  end

  def switch_default_ssl_account
    switch_ssl_account = params[:ssl_account_id]
    if switch_ssl_account && @user.get_all_approved_accounts.map(&:id).include?(switch_ssl_account.to_i)
      @user.set_default_ssl_account(switch_ssl_account)
      acct_number    = @user.ssl_accounts.find(switch_ssl_account).acct_number
      flash[:notice] = "You have switched to account #{acct_number}."
    else
      flash[:error] = "Something went wrong. Please try again!"
    end
    redirect_to account_path
  end

  def approve_account_invite
    user   = User.find params[:id]
    errors = user.approve_invite(params)
    if errors.any?
      flash[:error] = "Unable to approve due to errors. #{errors.join(' ')}"
    else
      acct_number = SslAccount.find(params[:ssl_account_id]).acct_number
      flash[:notice] = "You've been added to account #{acct_number}. Please click <strong>%s</strong>
        to go to the new account or follow the hint in the top menu."
      flash[:notice_item] = view_context.link_to('here',
        switch_default_ssl_account_user_path(ssl_account_id: params[:ssl_account_id]))
    end
    redirect_to account_path
  end

  def decline_account_invite
    user = User.find params[:id]
    if user.user_declined_invite?(params)
      flash[:error] = 'You have already declined this invite.'
    else
      account_number = SslAccount.find(params[:ssl_account_id]).acct_number
      if account_number
        user.decline_invite(params)
        flash[:notice] = "You have successfully declined a recent account invite for ##{account_number}."
      end
    end
    redirect_to account_path 
  end

  def resend_account_invite
    user   = User.find params[:id]
    errors = user.resend_invitation_with_token(params)
    if errors.any?
      flash[:error] = "Unable to send invitation due to errors. #{errors.join(' ')}"
    else
      flash[:notice] = 'You successfully renewed the invitation token and sent notification to the user.'
    end
    redirect_to users_path
  end

  def enable_disable
    update_user_status(params) if params[:user][:status]
    respond_to do |format|
      format.js {render json: @user.to_json}
    end  
  end

  private

  def new_user
    @user = User.new
  end

  def find_user
    if params[:id]
      @user=User.unscoped.find(params[:id])
    end
  end

  def admin_op?
    (@user!=@current_user &&
      (@current_user.is_admin? || @current_user.is_account_admin?)
    ) unless @current_user.blank?
  end

  def set_admin_flag
    @user.admin_update=true if admin_op?
  end

  def set_users
    if current_user.is_super_user? || current_user.is_admin?
      @users = User.unscoped
    else
      @users = current_user.manageable_users
    end
  end

  def admin_or_current_user?
    (@current_user.is_admin? || @current_user.is_account_admin?) || @current_user == @user
  end

  def render_invite_messages
    invites = current_user.get_pending_accounts
    if invites.any?
      invites.each do |invite|
        new_params = {ssl_account_id: invite[:ssl_account_id], token: invite[:approval_token]}
        accept_link = view_context.link_to('here',
          approve_account_invite_user_path(current_user, new_params))
        decline_link = view_context.link_to('decline',
          decline_account_invite_user_path(current_user, new_params))
        flash[:notice] = "You have been invited to join account ##{invite[:acct_number]}.
          Please click #{accept_link} to accept the invitation. Click %s to reject."
        flash[:notice_item] = decline_link
      end
    end
  end
end

def update_user_status(params)
  target_user   = User.unscoped.find params[:id]
  target_status = params[:user][:status].to_sym
  if target_user && target_status
    target_user.set_status_all_accounts(target_status) if current_user.is_system_admins?
    target_user.set_status_for_account(target_status, current_user.ssl_account) if current_user.is_account_admin?
  end
end
