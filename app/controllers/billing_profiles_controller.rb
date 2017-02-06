class BillingProfilesController < ApplicationController
  include ApplicationHelper, OrdersHelper
  #ssl_required :new
  #helper :profile
  filter_access_to :all
  filter_access_to :destroy, :create, :new, attribute_check: true
  respond_to :json
  
  before_filter :require_user

  def index
    permission_denied unless can_manage_profile?(params)
    @billing_profiles = current_user.ssl_account.billing_profiles
    @billing_profile  = BillingProfile.new
  end

  def destroy
    @bp=BillingProfile.find(params[:id])
    @bp.update_column :status, "disable"
    respond_with @bp
  end

  def new
    @billing_profile=BillingProfile.new
  end

  def create
    @billing_profile = current_user.ssl_account.billing_profiles.build(params[:billing_profile])
    if @billing_profile.save
      flash[:notice] = "Billing Profile successfully created!"
      if params[:manage_billing_profiles]
        redirect_to :back
      else
        redirect_to account_path
      end
    else
      if params[:manage_billing_profiles]
        @billing_profiles = current_user.ssl_account.billing_profiles
        render :index
      else
        render :new
      end
    end
  end

  private

  def can_manage_profile?(params)
    ssl_slug = params[:ssl_slug]
    manage   = false
    manage   = true if current_user.is_system_admins?
    unless manage || ssl_slug.nil?
      cur_ssl    = SslAccount.where('acct_number = ? || ssl_slug = ?', ssl_slug, ssl_slug).first
      profiles   = cur_ssl.billing_profiles if cur_ssl
      ssl_exists = current_user.ssl_accounts.include?(cur_ssl) if cur_ssl
      manage     = true if (ssl_exists && profiles.any? && profiles.first.users_can_manage.include?(current_user))
      if !manage && ssl_exists && profiles.empty?
        manage = true if (current_user.roles_for_account(cur_ssl) & Role.can_manage_billing).any?
      end
    end
    manage
  end
end
