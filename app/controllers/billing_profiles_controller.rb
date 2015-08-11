class BillingProfilesController < ApplicationController
  include ApplicationHelper, OrdersHelper
  #ssl_required :new
  #helper :profile
  filter_access_to :all

  respond_to :json
  
  before_filter :require_user

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
      redirect_to account_path
    else
      render action: "new"
    end

  end

end