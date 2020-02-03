# frozen_string_literal: true

class UsersController < ApplicationController
  # fix for https://sslcom.airbrake.io/projects/128852/groups/2108774376847787256?resolved=any&tab=overview
  skip_before_action :require_no_authentication, only: [:duo_verify]
  skip_before_action :verify_authenticity_token
  skip_before_action :finish_reseller_signup, only: [:cancel_reseller_signup]
  before_action :require_no_user, only: %i[new create]
  before_action :set_users, only: %i[index search]
  before_action :require_user, only: %i[
    show edit update cancel_reseller_signup
    approve_account_invite resend_account_invite
    switch_default_ssl_account enable_disable teams
    index admin_show search_teams archive_team retrieve_team
  ]
  before_action :new_user, only: %i[create new]
  before_action :find_ssl_account, only: %i[show admin_show]
  before_action :find_user, :set_admin_flag, only: %i[edit_email
                                                      edit_password update login_as admin_update admin_show
                                                      consolidate dup_info adjust_funds change_login
                                                      switch_default_ssl_account index admin_activate show teams]
  before_action :global_set_row_page, only: %i[index search teams]

  # before_filter :index, :only=>:search
  filter_access_to  :all
  filter_access_to  :update, :admin_update, :enable_disable,
                    :switch_default_ssl_account, :decline_account_invite,
                    :approve_account_invite, :create_team, :set_default_team,
                    :index, :edit_email, :edit_password, :leave_team, :dont_show_again, :archive_team, :retrieve_team, attribute_check: true
  filter_access_to  :consolidate, :dup_info, :archive_team, :retrieve_team, require: :update
  filter_access_to  :resend_activation, :activation_notice, require: :create
  filter_access_to  :edit_password, :edit_email, :cancel_reseller_signup, :teams, require: :edit
  filter_access_to  :show_user, :reset_failed_login_count, :avatar, require: :ajax

  def new; end

  def new_affiliate
    render action: 'new'
  end

  def search
    index
  end

  def search_teams
    if current_user.is_system_admins?
      if params[:search_term].present?
        s = params[:search_term]
        str = s.downcase
        @found_teams = SslAccount.where(
          'id = ? OR lower(acct_number) LIKE ? OR lower(company_name) LIKE ? OR lower(ssl_slug) LIKE ?',
          s, "%#{str}%", "%#{str}%", "%#{str}%"
        )
      end
      json = if @found_teams&.any?
               @order = Order.find_by(reference_number: params[:order]) if params[:order]
               @certificate_order = CertificateOrder.find_by(ref: params[:certificate_order]) if params[:certificate_order]
               { content: render_to_string(partial: '/orders/order_transfer_form', layout: false) }
             else
               { error: 'Team does not exist.' }
             end
    else
      json = { error: 'Not authorized to do this action!' }
    end
    render json: json
  end

  def index
    if params[:search]
      search = params[:search].strip.split(' ')
      role = nil
      search.delete_if do |s|
        s =~ /role\:(.+)/
        role ||= Regexp.last_match(1)
        Regexp.last_match(1)
      end
      search = search.join(' ')
      @users = @users.with_role(role).uniq if role
      @users = @users.search(search) if search.present?
    end
    @users = @users.order('created_at desc').paginate(@p)

    respond_to do |format|
      format.html { render action: :index }
      format.xml  { render xml: @users }
    end
  end

  def show_user
    if current_user
      user = User.unscoped.find(params[:id])
      render partial: 'details', locals: { user: user }
    else
      render json: 'no-user'
    end
  end

  def reset_failed_login_count
    data = {}

    if current_user
      user = User.unscoped.find(params[:id])
      user.update_attribute('failed_login_count', 0)

      data['status'] = 'success'
    else
      data['status'] = 'no-user'
    end

    render json: data
  end

  def create
    reseller = request.subdomain == Reseller::SUBDOMAIN
    User.transaction do
      if @user.signup!(params)
        @user.create_ssl_account
        if reseller
          @user.ssl_account.add_role! 'new_reseller'
          @user.ssl_account.set_reseller_default_prefs
        end
        @user.set_roles_for_account(
          @user.ssl_account,
          [Role.find_by(name: (reseller ? Role::RESELLER : Role::OWNER)).id]
        )

        if Settings.require_signup_password
          # Check Code Signing Certificate Order for assign as assignee.
          CertificateOrder.unscoped.search_validated_not_assigned(params[:user][:email]).each do |cert_order|
            cert_order.update_attribute(:assignee, @user)
            LockedRecipient.create_for_co(cert_order)
          end

          # TODO: New Logic for auto activation by signup with password.
          @user.deliver_auto_activation_confirmation!
          notice = 'Your account has been created.'
          flash[:notice] = notice

          # Auto Login after register
          @user_session = UserSession.new(
            login: params[:user][:login],
            password: params[:user][:password],
            failed_account: '0'
          )
          if @user_session.save
            user = @user_session.user
            set_cookie(:acct, user.ssl_account.acct_number)
            flash[:notice] = 'Successfully logged in.'
            redirect_to(account_path(user.ssl_account(:default_team) ?
                                                                   user.ssl_account(:default_team).to_slug :
                                                                   {})) && return
          end
        else
          # TODO: Original Logic for activation by email.
          @user.deliver_activation_instructions!
          notice = "Your account has been created. Please check your
            e-mail at #{@user.email} for your account activation instructions!"
          flash[:notice] = notice
        end

        # in production heroku, requests coming FROM a subdomain will not transmit
        # flash messages to the target page. works fine in dev though
        redirect_to(request.subdomain == Reseller::SUBDOMAIN ? login_url(notice: notice) : login_url)
      else
        render action: :new
      end
    end
  end

  def show
    if @user.ssl_account.has_credits? && @user.can_perform_accounting?
      flash.now[:warning] = 'You have unused ssl certificate credits. %s'
      flash.now[:warning_item] = 'Click here to view the list of credits.',
                                 credits_certificate_orders_path
    end
    render_invite_messages if @user.pending_account_invites?
  end

  def cancel_reseller_signup
    ssl        = current_user.ssl_account
    owner_role = Role.get_owner_id
    if current_user.role_symbols.include? Role::RESELLER.to_sym
      ssl.remove_role! 'new_reseller'
      ssl.reseller.destroy unless ssl.is_reseller? || ssl.reseller.blank?
      current_user.update_account_role(ssl, Role::RESELLER, Role::OWNER)
    end
    current_user.set_roles_for_account(ssl, [owner_role]) unless current_user.duplicate_role?(owner_role)
    flash[:notice] = 'reseller signup has been canceled'
    @user = current_user # for rabl object reference
  end

  def admin_show
    @ssl_slug = @ssl_account.to_slug if @ssl_account
  end

  def edit
    @user = User.find(params[:id]) if params[:update_own_team_limit] || params[:admin_activate]
  end

  def login_as; end

  def dup_info; end

  def adjust_funds
    amount = params['amount'].to_f * 100
    @user.ssl_account.funded_account.add_cents(amount)
    SystemAudit.create(owner: current_user, target: @user.ssl_account.funded_account,
                       notes: "amount (in USD): #{amount}",
                       action: 'FundedAccount#add_cents')
    redirect_to admin_show_user_path(@user)
  end

  def change_login
    old = @user.login
    @user.login = params['login']
    if @user.valid?
      User.change_login old, params['login']
      SystemAudit.create(owner: current_user, target: @user,
                         notes: "changed login from #{old} to #{params['login']}",
                         action: 'UserController#change_login')
    else
      @user.login = old
    end
    render action: :admin_show
  end

  def consolidate
    login = params[:login]
    email = params[:email]
    keep_login = (@user.login == login)
    keep_email = (@user.email == email)
    if keep_login && keep_email
      # delete all duplicate_v2_users
    elsif email && login && !(keep_login && keep_email)
      # change both
    elsif email
      # change email
    elsif login
      # change login
    end
    change_password
  end

  def edit_password
    @user ||= @current_user
    permission_denied if !@current_user.is_admin? && (@current_user != @user)
    @chpwd = !admin_op?
  end

  def edit_email
    @user ||= @current_user
    permission_denied unless admin_or_current_user?
  end

  def update
    @user ||= @current_user # makes our views "cleaner" and more consistent
    edit_email = params[:edit_action] == 'edit_email'
    unless edit_email
      @user.changing_password = true # nonelegant hack to trigger validations of password
      unless admin_op? || @user.valid_password?(params[:old_password])
        @user.errors[:base] <<
          'Old password value does not match password to be changed'
      end
    end
    old_address = @user.email # be sure to notify where changed from
    if @user.errors.empty? && @user.update(params[:user])
      flash[:notice] = 'Account updated.'
      if edit_email
        @user.deliver_email_changed!(old_address)
        @user.deliver_email_changed!
      else
        @user.deliver_password_changed!
      end
      redirect_to admin_op? ? users_url : edit_account_url
    elsif edit_email
      flash[:error] = 'Email is not a valid email.'
      redirect_to edit_email_users_path
    else
      @chpwd = !admin_op?
      render :edit_password
    end
  end

  def upload_avatar
    respond_to do |format|
      begin
        current_user.avatar = params[:file]
        current_user.save!
        format.js { render json: current_user.avatar.url, status: :ok }
        format.json { render json: current_user.avatar.url, status: :ok }
      rescue StandardError => e
        format.js { render json: e.message, status: :unprocessable_entity }
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  def admin_update
    respond_to do |format|
      if @user.update(params[:user])
        format.js { render json: @user.to_json }
      else
        format.js { render json: @user.errors.to_json }
      end
    end
  end

  def resend_activation
    if params[:login]
      @user = User.find_by login: params[:login]
      if @user
        if !@user.active?
          @user.deliver_activation_instructions!
          flash[:notice] = "Account activation instructions are on it's way - please check your e-mail for further instructions"
        else
          flash[:notice] = "Looks like user #{params[:login]} has already been activated"
        end
      else
        flash[:notice] = if DuplicateV2User.find_by login: params[:login]
                           "Ooops, looks like user #{params[:login]} has been consolidated with another account.
            Please contact support@ssl.com for more details"
                         else
                           "Ooops, looks like user #{params[:login]} doesn't exist in our system"
                         end
      end
      redirect_to login_path
    else
      redirect_to activation_notice_users_path
    end
  end

  def switch_default_ssl_account
    old_ssl_slug = @ssl_slug
    @switch_ssl_account = params[:ssl_account_id]
    session[:switch_ssl_account] = @switch_ssl_account
    session[:old_ssl_slug] = old_ssl_slug
    team = SslAccount.find(params[:ssl_account_id])
    if team.duo_enabled
      redirect_to duo_user_path(@user.id, ssl_slug: @ssl_slug)
    else
      if @switch_ssl_account && @user.get_all_approved_accounts.map(&:id).include?(@switch_ssl_account.to_i)
        @ssl_slug = SslAccount.find(@switch_ssl_account).to_slug
        @user.set_default_ssl_account(@switch_ssl_account)
        flash[:notice] = 'You have switched to team %s.'
        flash[:notice_item] = "<strong>#{SslAccount.find(@user.default_ssl_account).get_team_name}</strong>"
      else
        flash[:error] = 'Something went wrong. Please try again!'
      end
      redirect_to redirect_back_w_team_slug(old_ssl_slug)
    end
  end

  def duo
    team = SslAccount.find(session[:switch_ssl_account])
    if team.duo_own_used
      @duo_account = team.duo_account
      @duo_hostname = @duo_account.duo_hostname
      @sig_request = Duo.sign_request(@duo_account ? @duo_account.duo_ikey : '', @duo_account ? @duo_account.duo_skey : '', @duo_account ? @duo_account.duo_akey : '', current_user.login)
    else
      s = rails_application_secrets
      @duo_hostname = s.duo_api_hostname
      @sig_request = Duo.sign_request(s.duo_integration_key, s.duo_secret_key, s.duo_application_key, current_user.login)
    end
  end

  def duo_verify
    old_ssl_slug = session[:old_ssl_slug]
    @switch_ssl_account = session[:switch_ssl_account]
    @user = current_user
    team = SslAccount.find(session[:switch_ssl_account])
    if team.duo_own_used
      @duo_account = team.duo_account
      @authenticated_user = Duo.verify_response(@duo_account ? @duo_account.duo_ikey : '', @duo_account ? @duo_account.duo_skey : '', @duo_account ? @duo_account.duo_akey : '', params['sig_response'])
    else
      s = rails_application_secrets
      @authenticated_user = Duo.verify_response(s.duo_integration_key, s.duo_secret_key, s.duo_application_key, params['sig_response'])
    end
    if @authenticated_user
      if @switch_ssl_account && @user.get_all_approved_accounts.map(&:id).include?(@switch_ssl_account.to_i)
        @user.set_default_ssl_account(@switch_ssl_account)
        flash[:notice]      = 'You have switched to team %s.'
        flash[:notice_item] = "<strong>#{@user.ssl_account.get_team_name}</strong>"
        set_ssl_slug(@user)
      else
        flash[:error] = 'Something went wrong. Please try again!'
      end
      redirect_to account_path(ssl_slug: @ssl_slug)
    else
      redirect_to redirect_back_w_team_slug(old_ssl_slug)
    end
  end

  def approve_account_invite
    user   = User.find params[:id]
    errors = user.approve_invite(params)
    if errors.any?
      flash[:error] = "Unable to approve due to errors. #{errors.join(' ')}."
    else
      team = SslAccount.find(params[:ssl_account_id])
      flash[:notice] = "You have accepted the invitation to <strong>#{team.get_team_name}</strong>.<br />
        Would you like to set <strong>#{team.get_team_name}</strong> as your Default Team?
        <i>(This setting may be changed later.)</i><br />
        %s <span class='chip medium--grey'>NO</span><br /><br />
        The current default is <strong>#{user.ssl_account.get_team_name}</strong>."
      flash[:notice_item] = view_context.link_to("<span class='chip medium'>YES</span>".html_safe,
                                                 switch_default_ssl_account_user_path(ssl_account_id: params[:ssl_account_id]))
    end
    params[:to_teams] ? redirect_to(teams_user_path(user)) : redirect_to(account_path(ssl_slug: @ssl_slug))
  end

  def decline_account_invite
    user = User.find params[:id]
    if user.user_declined_invite?(params)
      flash[:error] = 'You have already declined this invite.'
    else
      ssl = SslAccount.find(params[:ssl_account_id])
      if ssl
        user.decline_invite(params)
        flash[:notice] = "You have successfully declined a recent account invite to team #{ssl.get_team_name}."
      end
    end
    params[:to_teams] ? redirect_to(teams_user_path(user)) : redirect_to(account_path(ssl_slug: @ssl_slug))
  end

  def resend_account_invite
    user   = User.find params[:id]
    errors = user.resend_invitation_with_token(params)
    if errors.any?
      flash[:error] = "Unable to send invitation due to errors. #{errors.join(' ')}"
    else
      flash[:notice] = 'You successfully renewed the invitation token and sent notification to the user.'
    end
    redirect_to users_path(ssl_slug: @ssl_slug)
  end

  def enable_disable
    update_user_status(params) if params[:user][:status]
    respond_to do |format|
      format.js { render json: @user.to_json }
    end
  end

  def enable_disable_duo
    update_user_duo_status(params) if params[:user][:duo_enabled]
    respond_to do |format|
      format.js { render json: @user.to_json }
    end
  end

  def teams
    # p = {page: params[:page]}
    team = params[:team]
    # @teams = @user.get_all_approved_accounts
    @teams = @user.get_all_approved_teams
    if team.present?
      team = team.strip.downcase
      # @teams = @teams.where("acct_number = ? OR ssl_slug = ? OR company_name = ?", team, team, team)
      @teams = @teams.search_team(team)
    end
    @teams = @teams.paginate(@p)
    @reseller_tiers = ResellerTier.general.map{ |rt| [rt.label + ' (' + rt.description['ideal_for'] + ')', rt.id] }
  end

  def archive_team
    team = (current_user.is_system_admins? ? SslAccount.unscoped : current_user.ssl_accounts).find(params[:ssl_account_id])
    team.archive! if team.active?

    flash[:notice] = 'Your team "#' + team.to_slug + '" has been archived. You can retrieve later again.'
    redirect_to teams_user_path(current_user)
  end

  def retrieve_team
    team = SslAccount.unscoped.find(params[:ssl_account_id])
    team.retrieve! if team.archived?

    flash[:notice] = 'Your team "#' + team.to_slug + '" has been retrieved.'
    redirect_to teams_user_path(current_user)
  end

  def create_team
    @user = User.find params[:id]
    if @user && !@user.max_teams_reached? && params[:create] && params[:team_name]
      @new_team = create_custom_ssl_acct(@user, params)
      if @new_team.persisted?
        flash[:notice] = "Team #{@new_team.company_name} has been successfully created."
        autoadd_users_to_team
        redirect_to teams_user_path
      else
        flash[:error] = 'Failed to create new team, please try again.'
        redirect_to :back
      end
    end
  end

  def autoadd_users_to_team
    if params[:auto_add_user_ids]&.any?
      users = User.where(id: params[:auto_add_user_ids].map(&:to_i))
      users.each do |user|
        user.ssl_accounts << @new_team

        # add roles from most recent team (shared w/current_user) they were added to
        roles = current_user.get_auto_add_user_roles(user)
        roles = [Role.get_individual_certificate_id] if roles.empty?
        user.set_roles_for_account(@new_team, roles)

        # send invitation email
        current_user.invite_existing_user(
          user: { email: user.email, ssl_account_id: @new_team.id },
          from_user: current_user
        )

        SystemAudit.create(
          owner:  current_user,
          target: user,
          action: 'Invite user to team (Users#create_team)',
          notes:  "Ssl.com user #{user.login} was invited to team #{@new_team.get_team_name} by #{current_user.login}."
        )
      end
    end
  end

  def set_default_team
    @user = User.find params[:id]
    if @user && params[:ssl_account_id]
      ssl = SslAccount.find(params[:ssl_account_id])
      if ssl && @user.set_default_team(ssl)
        flash[:notice] = "Team #{ssl.get_team_name} has been set as default team."
      else
        flash[:error] = 'Something went wrong, please try again.'
      end
    end
    redirect_to teams_user_path
  end

  def set_default_team_max
    @user = User.find params[:id]
    max   = params[:user][:max_teams]
    if @user && max
      @user.update(max_teams: max)
      flash[:notice] = "User #{@user.login} team limit has been successfully updated to #{max}."
    end
    redirect_to users_path
  end

  def leave_team
    @user    = User.find params[:id]
    team     = @user.ssl_accounts.find(params[:ssl_account_id]) if params[:ssl_account_id]
    own_team = (team.get_account_owner == @user) if team
    if team && !own_team
      @user.leave_team(team)
      flash[:notice] = "You have successfully left team #{team.get_team_name}."
    else
      flash[:error] = own_team ? 'You cannot leave team that you own!' : 'Something went wrong, please try again.'
    end
    redirect_to teams_user_path
  end

  def dont_show_again
    @user = User.find params[:id]
    @user.update(persist_notice: false)
    respond_to { |format| format.js { render json: 'ok' } }
  end

  def admin_activate
    @user = User.find params[:id]
    @user.activate!(params)
    if @user.valid?
      @user.approve_all_accounts(:log_invite)

      # Send activation email to user by system admin
      @user.deliver_activation_confirmation_by_sysadmin!(params[:user][:password])

      flash[:notice] = "User #{@user.login} has been successfully activated and sent email to " + params[:user][:login]
      redirect_to users_path
    else
      flash[:error] = "Unable to activate user due to errors. #{@user.errors.full_messages.join(', ')}"
      redirect_to edit_user_path(@user, admin_activate: true)
    end
  end

  def avatar
    respond_to do |format|
      data = UserSerializer.new(current_user).serializable_hash
      format.js do
        render json: data, status: :ok
      end
      format.json do
        render json: data, status: :ok
      end
    end
  end

  private

  def new_user
    @user = User.new
  end

  def find_user
    @user = if current_user.is_system_admins?
              if params[:id]
                User.unscoped.find(params[:id])
              elsif @ssl_account
                @ssl_account.get_account_owner
              else
                current_user
              end
            else
              current_user
            end
  end

  def admin_op?
    if @current_user.present?
      (@user != @current_user &&
        (@current_user.is_admin? || @current_user.is_owner?)
      )
    end
  end

  def set_admin_flag
    @user ||= current_user
    @user.admin_update = true if admin_op?
  end

  def set_users
    @users = if current_user&.is_system_admins?
               @ssl_account.try(:users) || User.unscoped
             else
               current_user&.manageable_users
             end
  end

  def admin_or_current_user?
    @current_user.is_admin? || @current_user == @user
  end

  def render_invite_messages
    invites = current_user.get_pending_accounts
    if invites.any?
      invites.each do |invite|
        new_params = { ssl_account_id: invite[:ssl_account_id], token: invite[:approval_token] }
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
    target_user.set_status_for_account(target_status, current_user.ssl_account) unless (current_user.roles_for_account & Role.can_manage_users).empty?
  end
end

def update_user_duo_status(params)
  target_user   = User.unscoped.find params[:id]
  target_status = params[:user][:duo_enabled].to_sym
  target_user.update_attribute(:duo_enabled, target_status)
end

def create_custom_ssl_acct(user, params)
  slug_valid = params[:ssl_slug] && SslAccount.ssl_slug_valid?(params[:ssl_slug])
  user.create_ssl_account(
    [Role.get_owner_id],
    company_name: params[:team_name], ssl_slug: (slug_valid ? params[:ssl_slug] : nil)
  )
end

def redirect_back_w_team_slug(replace_slug)
  req = request.env['HTTP_REFERER']
  req.present? ? req.gsub(replace_slug, @ssl_slug) : account_path(ssl_slug: @ssl_slug)
end
