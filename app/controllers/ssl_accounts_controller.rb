class SslAccountsController < ApplicationController
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
      @ssl_account = SslAccount.find params[:id]
    end
  end

  # GET /ssl_account/edit_settings
  def edit_settings
  end

  def update_ssl_slug
    ssl_slug = params[:ssl_account][:ssl_slug].downcase
    ssl      = SslAccount.find params[:ssl_account][:id]
    
    if ssl && SslAccount.ssl_slug_valid?(ssl_slug) && ssl.update(ssl_slug: ssl_slug)
      flash[:notice] = "You have successfully added url slug name #{params[:ssl_account][:ssl_slug]} to account."
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
    ssl = SslAccount.find params[:ssl_account][:id]
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

  # PUT /ssl_account/
  def update_settings
    if params[:reminder_notice_triggers]
      params[:reminder_notice_triggers].uniq.sort{|a,b|a.to_i <=> b.to_i}.
        reverse.each_with_index do |rt, i|
          @ssl_account.preferred_reminder_notice_triggers = rt.or_else(nil),
            ReminderTrigger.find(i+1)
      end
    end
    respond_to do |format|
      if @ssl_account.update_attributes(params[:ssl_account])
        flash[:notice] = 'Account settings were successfully updated.'
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
end
