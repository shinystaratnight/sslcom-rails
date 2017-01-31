class BillingProfilesController < ApplicationController
  include ApplicationHelper, OrdersHelper
  #ssl_required :new
  #helper :profile
  filter_access_to :all
  filter_access_to :destroy, :create, :new, attribute_check: true
  respond_to :json
  
  before_filter :require_user

  def index
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
end
