class SslAccountsController < ApplicationController
  before_action :require_user, only: %i[show edit edit_settings manage_reseller remove_reseller]
  before_action :find_ssl_account
  skip_before_action :verify_duo_authentication, only: %i[set_2fa_type register_duo]
  filter_access_to :all, attribute_check: true

  # GET /ssl_account/
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @ssl_account }
    end
  end

  # GET /ssl_account/edit
  def edit
    if params[:url_slug] || params[:update_company_name]
      @ssl_account = (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find(params[:id]) if params[:id]
    end
  end

  # GET /ssl_account/edit_settings
  def edit_settings
    # Generate one for each version of U2F, currently only `U2F_V2`
    @registration_requests = u2f.registration_requests

    # Store challenges. We need them for the verification step
    session[:challenges] = @registration_requests.map(&:challenge)

    # Fetch existing Registrations from your db and generate SignRequests
    key_handles = current_user.u2fs.pluck(:key_handle)
    @sign_requests = u2f.authentication_requests(key_handles)
    @duo_account = current_user_default_team.duo_account

    @app_id = u2f.app_id
  end

  def update_ssl_slug
    ssl_slug = params[:ssl_account][:ssl_slug].downcase
    ssl      = SslAccount.find params[:ssl_account][:id]

    if ssl && SslAccount.ssl_slug_valid?(ssl_slug) && ssl.update(ssl_slug: ssl_slug)
      flash[:notice] = "You have successfully changed your team url to https://#{Settings.portal_domain}/team/#{params[:ssl_account][:ssl_slug]}."
      if current_user.is_system_admins?
        redirect_to users_path
      else
        set_ssl_slug(@user)
        redirect_to account_path(ssl_slug: @ssl_slug)
      end
    else
      flash[:error] = "Please try again using a valid slug name. #{ssl.errors.full_messages.join(', ')}."
      redirect_to edit_ssl_account_path(params[:ssl_account].merge(url_slug: true))
    end
  end

  def validate_ssl_slug
    respond_to do |format|
      format.js { render json: { message: SslAccount.ssl_slug_valid?(params[:ssl_slug_name]) } }
    end
  end

  def update_company_name
    ssl = (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find params[:ssl_account][:id]
    if ssl&.update(company_name: params[:ssl_account][:company_name])
      flash[:notice] = "Company name has been successfully updated to #{ssl.company_name}"
      redirect_to account_path(ssl_slug: @ssl_slug)
    else
      flash[:error] = "Company name has NOT been updated due to errors! #{ssl.errors.full_messages.join(', ')}"
      redirect_to edit_ssl_account_path(params[:ssl_account].merge(update_company_name: true))
    end
  end

  # PUT /ssl_account/
  def update
    if params[:billing_method]
      update_billing_method
    elsif params[:no_limit]
      update_no_limit
    elsif params[:epki_agreement]
      update_epki_agreement
    else
      update_reseller_profile
    end
  end

  def register_duo
    response = {}
    if current_user_default_team.duo_account
      current_user_default_team.duo_account.update(params.except(:action, :controller))
    else
      current_user_default_team.create_duo_account
      current_user_default_team.duo_account.update(params.except(:action, :controller))
    end
    render json: response
  end

  # PUT /ssl_account/
  def update_settings
    if params[:reminder_notice_triggers]
      params[:reminder_notice_triggers].uniq.sort_by(&:to_i)
                                       .reverse.each_with_index do |rt, i|
        @ssl_account.preferred_reminder_notice_triggers = rt.or_else(nil),
                                                          ReminderTrigger.find(i + 1)
      end
    end

    respond_to do |format|
      if @ssl_account.update(params[:ssl_account])
        flash[:notice] = 'Account settings were successfully updated.'

        format.html { redirect_to(account_path(ssl_slug: @ssl_slug)) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit_settings' }
        format.xml  { render xml: @ssl_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ssl_account/duo_enable
  def duo_enable
    @ssl_account.update_attribute(:duo_enabled, params['duo_enable'])
    respond_to do |format|
      format.js { render json: @user.to_json }
    end
  end

  # PUT /ssl_account/duo_own_used
  def duo_own_used
    @ssl_account.update_attribute(:duo_own_used, params['duo_own_used'])
    respond_to do |format|
      format.js { render json: @user.to_json }
    end
  end

  # PUT /ssl_account/set_2fa_type
  # Toggle ssl_account.sec_type (u2f or duo)
  def set_2fa_type
    type = @ssl_account.sec_type == params['sec_type'] ? '' : params['sec_type']
    @ssl_account.update_attribute(:sec_type, type)
    respond_to do |format|
      format.js { render json: @ssl_account.to_json }
    end
  end

  def adjust_funds
    amount = params['amount'].to_f * 100
    @ssl_account.funded_account.add_cents(amount)
    SystemAudit.create(owner: current_user, target: @ssl_account.funded_account,
                       notes: "amount (in USD): #{amount}",
                       action: 'FundedAccount#add_cents')
    if current_user.is_system_admins?
      redirect_to teams_user_path(current_user)
    else
      redirect_to admin_show_user_path(@ssl_account.get_account_owner)
    end
  end

  def remove_reseller
    team = SslAccount.find_by(acct_number: params[:ssl_account_ref]) ||
           SslAccount.find_by(ssl_slug: params[:ssl_account_ref])

    team.users.each do |u|
      u.assignments.where(
        role_id: [Role.find_by(name: Role::RESELLER).id],
        ssl_account_id: team.id
      ).destroy_all
    end

    team.remove_role! 'reseller' if team.reseller.destroy!

    render json: true
  end

  def manage_reseller
    team = SslAccount.find_by(acct_number: params[:ssl_account_ref]) ||
           SslAccount.find_by(ssl_slug: params[:ssl_account_ref])
    reseller_fields = {}

    Reseller::TEMP_FIELDS.keys.each do |key|
      reseller_fields[key] = params[key.to_sym]
    end

    team.adjust_reseller_tier(params[:reseller_tier], reseller_fields)

    render json: true
  end

  private

  def update_no_limit
    if current_user.is_system_admins?
      ssl_account = SslAccount.where(
        'ssl_slug = ? OR acct_number = ?', params[:ssl_slug], params[:ssl_slug]
      ).first
      ssl_account.update(no_limit: params[:no_limit])
      setting_type = params[:no_limit] == 'false' ? 'OFF' : 'ON'
      flash[:notice] = "Successfully turned #{setting_type} team #{params[:ssl_slug]} no-limit setting."
    else
      flash[:error] = 'You are not authorized to perform this action.'
    end
    redirect_to teams_user_path(current_user, page: (params[:page] || 1))
  end

  def update_epki_agreement
    if current_user.is_system_admins?
      ssl_account = SslAccount.where(
        'ssl_slug = ? OR acct_number = ?', params[:ssl_slug], params[:ssl_slug]
      ).first
      setting_type = params[:epki_agreement] == 'false' ? 'OFF' : 'ON'
      ssl_account.update(
        epki_agreement: (setting_type == 'OFF' ? nil : DateTime.now)
      )
      flash[:notice] = "Successfully turned #{setting_type} team #{params[:ssl_slug]} epki_agreement setting."
    else
      flash[:error] = 'You are not authorized to perform this action.'
    end
    redirect_to teams_user_path(current_user, page: (params[:page] || 1))
  end

  def update_billing_method
    if current_user.is_system_admins?
      ssl_account = SslAccount.where(
        'ssl_slug = ? OR acct_number = ?', params[:ssl_slug], params[:ssl_slug]
      ).first
      ssl_account.update(billing_method: params[:billing_method])
      flash[:notice] = "Successfully updated team #{params[:ssl_slug]} to '#{params[:billing_method]}' billing."
    else
      flash[:error] = 'You are not authorized to perform this action.'
    end
    redirect_to teams_user_path(current_user, page: (params[:page] || 1))
  end

  def update_reseller_profile
    if current_user.is_system_admins?
      @ssl_account = Reseller.find(params[:ssl_account][:reseller_attributes][:id]).ssl_account
      @ssl_slug = @ssl_account.to_slug
    end
    respond_to do |format|
      if @ssl_account.update(params[:ssl_account])
        flash[:notice] = 'Reseller profile information was successfully updated.'
        format.html { redirect_to(account_path(ssl_slug: @ssl_slug)) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @ssl_account.errors, status: :unprocessable_entity }
      end
    end
  end
end
