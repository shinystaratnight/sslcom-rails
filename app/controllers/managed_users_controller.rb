class ManagedUsersController < ApplicationController
  before_action    :require_user
  filter_access_to :new, :create
  filter_access_to :edit, :update_roles, :remove_from_account, attribute_check: true

  def new
    @user=User.new
  end

  def create
    ssl_account_ids = params[:user][:ssl_account_ids].reject(&:blank?).map(&:to_i).compact
    user_exists = User.get_user_by_email(params[:user][:email])
    if user_exists && user_exists.is_admin_disabled?
      disabled_user_invited(user_exists, ssl_account_ids)
      redirect_to users_path(ssl_slug: @ssl_slug)
    else
      manage_invites = current_user.total_teams_can_manage_users.map(&:id) & ssl_account_ids
      @ssl_accounts = manage_invites.any? ? SslAccount.where(id: manage_invites) : []
      ignore_teams = user_exists_for_teams(params[:user][:email])
      ignore_teams = ignore_teams.map(&:get_team_name).join(', ') unless ignore_teams.empty?
      if @ssl_accounts.empty?
        @user = User.new
        flash[:error] = if manage_invites.blank? && ssl_account_ids.any?
          "You do not have permission to invite users to #{ssl_account_ids.count} team(s)!"
        else
          "User #{params[:user][:email]} already exists for these teams: #{ignore_teams}!"
        end
        render :new
      else
        new_params  = params.merge(root_url: root_url, from_user: current_user)
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
    ssl_accounts = params[:user][:ssl_account_ids].reject(&:blank?).compact
    role_ids     = params[:user][:role_ids].reject(&:blank?)
    role_change  = params[:user][:role_change_type]
    if ssl_accounts.empty? || role_ids.empty?
      flash[:error] = 'Must select at least one role and one team.'
      redirect_to edit_managed_user_path
    else
      params[:user][:role_ids] = (role_ids & User.roles_list_for_user(current_user).ids.map(&:to_s))
      @user         = User.find(params[:id])
      ssl_select    = ssl_accounts.map(&:to_i)
      ssl_user      = @user.ssl_accounts.pluck(:id)
      ssl_update    = SslAccount.where(id: (ssl_select & ssl_user)) # update roles for teams
      @ssl_accounts = SslAccount.where(id: (ssl_select - ssl_user)) # invite to teams
      
      # update roles for user's existing teams
      ssl_update.map(&:id).each do |ssl|
        params[:user][:ssl_account_id] = ssl
        if role_change == 'overwrite'
          @user.assign_roles(params)
          @user.remove_roles(params)
        elsif role_change == 'add'
          @user.assign_roles(params)
        else
          @user.remove_roles(params, true)
        end
      end
      # invite existing user to new teams w/selected roles  
      unless @ssl_accounts.empty?
        new_params = params.merge(root_url: root_url, from_user: current_user)
        invite_user_to_team(@user, new_params, (request.subdomain == Reseller::SUBDOMAIN), true)
      end
      notice =  "#{@user.email} roles have been updated for teams: #{ssl_update.map(&:get_team_name).join(', ')}."
      notice << " And, invited to teams: #{@ssl_accounts.map(&:get_team_name).join(', ')}." unless @ssl_accounts.empty?
      @user.touch
      redirect_to users_path(ssl_slug: @ssl_slug), notice: notice
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
    unless reseller || role_ids.include?(acc_admin_user.to_s)
      role_ids << acc_admin_user if role_ids.empty?
    end
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
      SystemAudit.create(
        owner:  current_user, 
        target: user,
        action: 'Invite user to team (ManagedUsersController#create)',
        notes:  "#{existing_user ? 'Ssl.com' : 'New'} user #{user.login} was invited to team #{ssl_account.get_team_name} by #{current_user.login}.")
    end
    unless existing_user
      user.approve_all_accounts(:log_invite)
      user.invite_new_user(params.merge(deliver_invite: true, invited_teams: @ssl_accounts))
    end
  end

  def disabled_user_invited(disabled_user, ssl_account_ids)
    ssl_accounts = SslAccount.where(id: ssl_account_ids.reject(&:blank?).compact)
    if ssl_accounts.any?
      ssl_accounts.each do |team|
        disabled_user.deliver_invite_to_account_disabled!(team, current_user)
      end
    end
    flash[:error] = "User #{params[:user][:email]} has been disabled by SSL.com and cannot be invited at this moment!"
  end
end
