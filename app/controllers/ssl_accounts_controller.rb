class SslAccountsController < ApplicationController
  before_filter :find_ssl_account
  filter_access_to :all, attribute_check: true
  filter_access_to :edit_settings, :update_settings, :require=>:update

  # GET /ssl_account/
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ssl_account }
    end
  end

  # GET /ssl_account/edit
  def edit
  end

  # GET /ssl_account/edit_settings
  def edit_settings
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

  private

  def find_ssl_account
    @ssl_account = current_user.ssl_account
  end
end
