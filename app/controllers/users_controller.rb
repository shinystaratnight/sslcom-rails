class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update, :cancel_reseller_signup]
  before_filter :finish_reseller_signup, :only => [:show]
  before_filter :new_user, :only=>[:create, :new]
  before_filter :find_user, :set_admin_flag, :only=>[:edit_email, 
    :edit_password, :update, :login_as, :admin_update, :admin_show,
    :consolidate, :dup_info]
#  before_filter :index, :only=>:search
  filter_access_to  :all
  filter_access_to  :update, :admin_update, attribute_check: true
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

  # GET /users
  # GET /users.xml
  def index
    p = {:page => params[:page]}
    p.merge!({:conditions=>["login #{SQL_LIKE} ? OR email #{SQL_LIKE} ?",
      '%'+@search+'%', '%'+@search+'%']}) if @search = params[:search]
    @users = User.unscoped.order(:created_at.desc).paginate(p)
    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @users }
    end
  end

  def create
    @user.create_ssl_account
    if current_subdomain==Reseller::SUBDOMAIN
      @user.ssl_account.add_role! "new_reseller"
      @user.ssl_account.set_reseller_default_prefs
      @user.roles << Role.find_by_name(Role::RESELLER)
    else
      @user.roles << Role.find_by_name(Role::CUSTOMER)
    end
    if @user.signup!(params)
      @user.deliver_activation_instructions!
      notice = "Your account has been created. Please check your
        e-mail at #{@user.email} for your account activation instructions!"
      flash[:notice] = notice
      #in production heroku, requests coming FROM a subdomain will not transmit
      #flash messages to the target page. works fine in dev though
      redirect_to(current_subdomain==Reseller::SUBDOMAIN ? root_url(:notice=>notice) : root_url)
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
  end

  def cancel_reseller_signup
    if current_user.role_symbols.include? Role::RESELLER.to_sym
      current_user.ssl_account.remove_role! "new_reseller"
      current_user.ssl_account.reseller.destroy unless current_user.ssl_account.reseller.blank?
      current_user.roles.delete Role.find_by_name(Role::RESELLER)
    end
    current_user.roles << Role.find_by_name(Role::CUSTOMER) unless current_user.role_symbols.include?(Role::CUSTOMER.to_sym)
    flash[:notice]="reseller signup has been canceled"
    @user=current_user #for rable object reference
  end

  def admin_show    
  end

  def edit
  end

  def login_as
  end

  def dup_info
  end

  def consolidate
    login, email=params[:login], params[:email]
    keep_login = (@user.login==login)
    keep_email = (@user.email==email)
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
    permission_denied if (!@current_user.is_admin? && @current_user != @user)
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
      redirect_to root_path
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
    (@user!=@current_user && @current_user.is_admin?) unless @current_user.blank?
  end

  def set_admin_flag
    @user.admin_update=true if admin_op?
  end
end