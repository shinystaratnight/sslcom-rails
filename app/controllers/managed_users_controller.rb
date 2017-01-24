class ManagedUsersController < ApplicationController
  before_filter    :require_user
  filter_access_to :all

  def new
    @user=User.new
  end

  def create
    @ssl_accounts = SslAccount.where(
      id: params[:user][:ssl_account_ids].reject(&:blank?).compact
    )
    ignore_teams = user_exists_for_teams(params[:user][:email])
    ignore_teams = ignore_teams.map(&:get_team_name).join(', ') unless ignore_teams.empty?
    if @ssl_accounts.empty?
      @user         = User.new
      flash[:error] = "User #{params[:user][:email]} already exists for these teams: #{ignore_teams}!"
      render :new
    else
      new_params  = params.merge(root_url: root_url, from_user: current_user)
      user_exists = User.get_user_by_email(params[:user][:email])
      @user       = current_user.invite_user_to_account!(new_params)
      if @user.persisted?
        invite_user_to_team(
          @user, new_params, (request.subdomain == Reseller::SUBDOMAIN), user_exists
        )
        flash_notice = "An invitation email has been sent to #{@user.email} 
          for teams #{@ssl_accounts.map(&:get_team_name).join(', ')}."
        unless ignore_teams.blank? || ignore_teams.empty?
          flash_notice << " User already exisits for team(s) #{ignore_teams}."
        end
        flash[:notice] = flash_notice
        redirect_to users_path(ssl_slug: @ssl_slug)
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
    ssl_accounts = params[:user][:ssl_account_ids].reject(&:blank?)
    role_ids     = params[:user][:role_ids].reject(&:blank?)
    if ssl_accounts.empty? || role_ids.empty?
      flash[:error] = 'Must select at least one role and one team.'
      redirect_to edit_managed_user_path
    else
      params[:user][:role_ids] = (role_ids & User.roles_list_for_user(current_user).ids.map(&:to_s))
      @user = User.find(params[:id])
      teams = SslAccount.where(id: ssl_accounts).map(&:get_team_name).join(', ')
      ssl_accounts.compact.each do |ssl|
        params[:user][:ssl_account_id] = ssl
        @user.assign_roles(params)
        @user.remove_roles(params)
      end
      flash[:notice] = "#{@user.email} roles have been updated for teams: #{teams}."
      redirect_to users_path(ssl_slug: @ssl_slug)
    end
  end

  def remove_from_account
    @user   = User.find(params[:id])
    account = SslAccount.find(params[:ssl_account_id]) if params[:ssl_account_id]
    account = account ? account : current_user.ssl_account
    unless account.get_account_owner == @user
      @user.remove_user_from_account(account, current_user)
      flash[:notice] = "#{@user.email} has been removed from account '#{account.acct_number}' and is being notified."
    else
      flash[:notice] = "#{@user.email} is the owner of account '#{account.acct_number}' and cannot be removed."
    end
    redirect_to users_path(ssl_slug: @ssl_slug)
  end

  private

  def get_role_ids(role_ids, reseller)
    role_ids       = role_ids || []
    acc_admin_user = Role.get_account_admin_id
    role_ids << acc_admin_user unless (reseller || role_ids.include?(acc_admin_user.to_s))
    role_ids << Role.get_role_id(Role::RESELLER) if reseller
    role_ids
  end

  def user_exists_for_teams(email)
    ignore_teams  = []
    @ssl_accounts = @ssl_accounts.inject([]) do |filtered_ssl, ssl|
      user_exists = current_user.user_exists_for_account?(email, ssl)
      ignore_teams << ssl if user_exists
      filtered_ssl << ssl unless user_exists
      filtered_ssl
    end
    ignore_teams
  end

  def invite_user_to_team(user, params, reseller, existing_user)
    roles = (get_role_ids(params[:user][:role_ids], reseller)).reject(&:blank?).compact
    @ssl_accounts.each do |ssl_account|
      if reseller
        ssl_account.add_role! 'new_reseller'
        ssl_account.set_reseller_default_prefs
      end
      user.ssl_accounts << ssl_account
      user.set_roles_for_account(ssl_account, roles)
      if existing_user
        params[:user][:ssl_account_id] = ssl_account.id
        user.invite_existing_user(params)
      end
    end
    unless existing_user
      user.approve_all_accounts
      user.invite_new_user(params.merge(deliver_invite: true))
    end
  end
end
