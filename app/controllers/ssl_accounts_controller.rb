class SslAccountsController < ApplicationController
  before_filter :require_user, only: [:show, :edit, :edit_settings]
  before_filter :find_ssl_account
  filter_access_to :all, attribute_check: true

  # GET /ssl_account/
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ssl_account }
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
    # key_handles = Registration.map(&:key_handle)
    key_handles = current_user.u2fs.pluck(:key_handle)
    @sign_requests = u2f.authentication_requests(key_handles)

    @app_id = u2f.app_id
  end

  def update_ssl_slug
    ssl_slug = params[:ssl_account][:ssl_slug].downcase
    ssl      = SslAccount.find params[:ssl_account][:id]
    
    if ssl && SslAccount.ssl_slug_valid?(ssl_slug) && ssl.update(ssl_slug: ssl_slug)
      flash[:notice] = "You have successfully changed your team url to https://www.ssl.com/team/#{params[:ssl_account][:ssl_slug]}."
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
      format.js {render json: {message: SslAccount.ssl_slug_valid?(params[:ssl_slug_name])}}
    end
  end

  def update_company_name
    ssl = (current_user.is_system_admins? ? SslAccount : current_user.ssl_accounts).find params[:ssl_account][:id]
    if ssl && ssl.update(company_name: params[:ssl_account][:company_name])
      flash[:notice] = "Company name has been successfully updated to #{ssl.company_name}"
      redirect_to account_path(ssl_slug: @ssl_slug)
    else
      flash[:error] = "Company name has NOT been updated due to errors! #{ssl.errors.full_messages.join(', ')}"
      redirect_to edit_ssl_account_path(params[:ssl_account].merge(update_company_name: true))
    end
  end

  # PUT /ssl_account/
  def update
    params[:monthly_billing] ? update_monthly_billing : update_reseller_profile
  end

  # PUT /ssl_account/
  def update_settings
    # *************************** TODO: Testing ***************************
    # temp_u2f_response = {
    #     'registrationData'=>'BQTiHTk7ui4mormExZ1G70IACAaV1S9CpQDACWBbs1I4s_BUvBP39tnzTm-TIY0R28bBzGeGxxSLerpxbSAVOYIDQDueolFjTiRAitlxRNcx1y5vKlN14f0OYQlKNawBBKTM7Lb0gwTLfdSyXFo93TIp4O1-88rEI4LWVaU4ZvQIWj8wggE1MIHcoAMCAQICCwDY4Y_UyJucCPduMAoGCCqGSM49BAMCMBUxEzARBgNVBAMTClUyRiBJc3N1ZXIwGhcLMDAwMTAxMDAwMFoXCzAwMDEwMTAwMDBaMBUxEzARBgNVBAMTClUyRiBEZXZpY2UwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARa9fZ556cZWqmmoAN3rWErKUu3r6YODFcI0Wf9hH0UW65YTEsq33U_2397bZnJON8tPqHO0O9jAA-YgikhTTLooxcwFTATBgsrBgEEAYLlHAIBAQQEAwIFIDAKBggqhkjOPQQDAgNIADBFAiEAwaOmji8WpyFGJwV_YrtyjJ4D56G6YtBGUk5FbSwvP3MCIAtfeOURqhgSn28jbZITIn2StOZ-31PoFt-wXZ3IuQ_eMEQCIHSibtLw2ShFqhSha8btuURH67OYL0e6Px46xyCUYCIbAiA-Gh8y_lfrDHS4c8foXxoDzBRBYCeyJGNVtVpmbfRY9w',
    #     'version'=>'U2F_V2',
    #     'challenge'=>'Awb4tNZaXIHU5WDVZnw-U8CthkqhtkYinK0tetrm6qs',
    #     'clientData'=>'eyJ0eXAiOiJuYXZpZ2F0b3IuaWQuZmluaXNoRW5yb2xsbWVudCIsImNoYWxsZW5nZSI6IkF3YjR0TlphWElIVTVXRFZabnctVThDdGhrcWh0a1lpbkswdGV0cm02cXMiLCJvcmlnaW4iOiJodHRwczovL3NhbmRib3gzLnNzbC5jb20iLCJjaWRfcHVia2V5IjoidW51c2VkIn0'
    # }
    # params[:u2f_response] = temp_u2f_response.to_json
    # *********************************************************************

    if params[:reminder_notice_triggers]
      params[:reminder_notice_triggers].uniq.sort{|a,b|a.to_i <=> b.to_i}.
        reverse.each_with_index do |rt, i|
          @ssl_account.preferred_reminder_notice_triggers = rt.or_else(nil),
            ReminderTrigger.find(i+1)
      end
    end

    unless params[:u2f_response].blank?
      response = U2F::RegisterResponse.load_from_json(params[:u2f_response])
      exist = current_user.u2fs.find_by_key_handle(response.key_handle)

      if exist
        flash[:error] = "This U2F device has already been registered."
      else
        begin
          reg = u2f.register!(session[:challenges], response)
          # *************************** TODO: Testing ***************************
          # reg = u2f.register!(['Awb4tNZaXIHU5WDVZnw-U8CthkqhtkYinK0tetrm6qs'], response)
          # *********************************************************************

          # save a reference to your database
          current_user.u2fs.create!(certificate: reg.certificate,
                                    key_handle:  reg.key_handle,
                                    public_key:  reg.public_key,
                                    counter:     reg.counter)

          # current_user.u2fs.create!(certificate: "CERTIFICATE",
          #                          key_handle:  "weqmtkmMMKSFWWRSDsadkfASfs",
          #                          public_key:  "sadfjqwer2342jfasd23jksfsa",
          #                          counter:     1)
        rescue U2F::Error => e
          # return "Unable to register: <%= e.class.name %>"
          flash[:error] = "Unable to register: " + e.class.name
        ensure
          session.delete(:challenges)
          flash[:notice] = 'New U2F device has been registered successfully.'
        end
      end
    end

    respond_to do |format|
      if @ssl_account.update_attributes(params[:ssl_account])
        flash[:notice].blank? ?
            flash[:notice] = "Account settings were successfully updated." :
            flash[:notice] += "<br /> Account settings were successfully updated."

        format.html { redirect_to(account_path(ssl_slug: @ssl_slug)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_settings" }
        format.xml  { render :xml => @ssl_account.errors, :status => :unprocessable_entity }
      end
    end
  end

  def adjust_funds
    amount=params["amount"].to_f*100
    @ssl_account.funded_account.add_cents(amount)
    SystemAudit.create(owner: current_user, target: @ssl_account.funded_account,
                       notes: "amount (in USD): #{amount.to_s}",
                       action: "FundedAccount#add_cents")
    redirect_to admin_show_user_path(@ssl_account.get_account_owner)
  end
  
  private
  
  def update_monthly_billing
    if current_user.is_system_admins?
      ssl_account = SslAccount.where(
        'ssl_slug = ? OR acct_number = ?', params[:ssl_slug], params[:ssl_slug]
      ).first 
      ssl_account.update(billing_method: (params[:status] == 'enable' ? 'monthly' : 'due_at_checkout'))
      flash[:notice] = "Successfully #{params[:status]}d team #{params[:ssl_slug]} monthly billing."
    else
      flash[:error] = "You are not authorized to perform this action."
    end  
    redirect_to teams_user_path(current_user)
  end  
    
  def update_reseller_profile
    respond_to do |format|
      if @ssl_account.update_attributes(params[:ssl_account])
        flash[:notice] = 'Reseller profile information was successfully updated.'
        format.html { redirect_to(account_path(ssl_slug: @ssl_slug)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ssl_account.errors, :status => :unprocessable_entity }
      end
    end
  end
end
