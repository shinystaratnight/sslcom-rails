class BillingProfilesController < ApplicationController
  include ApplicationHelper, OrdersHelper
  #ssl_required :new
  #helper :profile
  before_action :require_user, :find_ssl_account
  filter_access_to :all
  filter_access_to :destroy, attribute_check: true
  respond_to :json

  def index
    @billing_profile  = BillingProfile.new
    p = {:page => params[:page]}
    unpaginated =
        if @search = params[:search]
          if current_user.is_system_admins?
            (@ssl_account.try(:billing_profiles) ? BillingProfile.unscoped{@ssl_account.try(:billing_profiles)} :
                 BillingProfile.unscoped).search(params[:search])
          else
            current_user.ssl_account.billing_profiles.search(params[:search])
          end
        else
          if current_user.is_system_admins?
            (@ssl_account.try(:billing_profiles) ? BillingProfile.unscoped{@ssl_account.try(:billing_profiles)} : BillingProfile.unscoped).order("created_at desc")
          else
            current_user.ssl_account.billing_profiles
          end
        end
    @billing_profiles=unpaginated.paginate(p)
    respond_to do |format|
      format.html { render :action => :index}
      format.xml  { render :xml => @billing_profiles }
    end
  end

  def destroy
    @bp=BillingProfile.find(params[:id])
    @bp.update_column :status, "disable"
    respond_with @bp
  end

  def new
    @billing_profile=BillingProfile.new
  end
  
  def update
    bp = @ssl_account.billing_profiles.find_by(id: params[:id])
    if bp && params[:set_default]
      if bp.update(default_profile: true)
        flash[:notice] = "Succesfully set billing profile ending in #{bp.last_digits} to default"
      end
    end
    redirect_to billing_profiles_path(@ssl_slug)
  end
  
  def create
    @billing_profile = @ssl_account.billing_profiles.build(params[:billing_profile])
    if @billing_profile.save
      flash[:notice] = "Billing Profile successfully created!"
      if params[:manage_billing_profiles]
        redirect_to :back
      else
        redirect_to account_path
      end
    else
      if params[:manage_billing_profiles]
        @billing_profiles = @ssl_account.billing_profiles
        render :index
      else
        render :new
      end
    end
  end
end
