class ManagedUsersController < ApplicationController
  before_filter    :require_user
  filter_access_to :all

  def new
    @user=User.new
  end

  def create
    ssl_account = current_user.ssl_account
    if current_user.user_exists_for_account?(params[:user][:email])
      @user=User.new
      flash[:error] = "User #{params[:user][:email]} already exists for this account!"
      render :new
    else
      new_params  = params.merge(root_url: root_url, from_user: current_user)
      user_exists = User.get_user_by_email(params[:user][:email])
      @user       = current_user.invite_user_to_account!(new_params)
      reseller    = (request.subdomain == Reseller::SUBDOMAIN)
      if @user.persisted?
        if reseller
          ssl_account.add_role! 'new_reseller'
          ssl_account.set_reseller_default_prefs
        end
        @user.ssl_accounts << ssl_account
        @user.set_roles_for_account(ssl_account,
          (get_role_ids(params[:user][:role_ids], reseller)).reject(&:blank?).compact
        )
        
        @user.invite_existing_user(new_params) if user_exists
        unless user_exists
          @user.approve_all_accounts
          @user.invite_new_user(new_params.merge(deliver_invite: true))
        end

        flash[:notice] = "An invitation email has been sent to #{@user.email}."
        redirect_to users_path
      else
        render :new
      end
    end
  end

  def edit
    @user = User.find(params[:id])
    if current_user.is_system_admins?
      @user_accounts_roles = User.get_user_accounts_roles(@user)
    end
    @role_ids = @user.roles_for_account(current_user.ssl_account)
    render :update_roles
  end

  def update_roles
    @user = User.find(params[:id])
    @user.assign_roles(params)
    @user.remove_roles(params)
    flash[:notice] = "#{@user.email} roles have been updated."
    redirect_to users_path
  end

  def remove_from_account
    @user   = User.find(params[:id])
    account = SslAccount.find(params[:ssl_account_id]) if params[:ssl_account_id]
    account = account ? account : current_user.ssl_account
    @user.remove_user_from_account(account, current_user)
    flash[:notice] = "#{@user.email} has been removed from account '#{account.acct_number}' and is being notified."
    redirect_to users_path
  end

  private

  def get_role_ids(role_ids, reseller)
    role_ids = role_ids || []
    ssl_user = Role.get_role_id(Role::SSL_USER)
    role_ids << ssl_user unless (reseller || role_ids.include?(ssl_user.to_s))
    role_ids << Role.get_role_id(Role::RESELLER) if reseller
    role_ids
  end
end
