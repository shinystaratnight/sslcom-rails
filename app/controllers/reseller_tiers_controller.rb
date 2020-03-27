class ResellerTiersController < ApplicationController
  before_action :require_user, :only => [:edit,:new]
  before_action :require_admin, :only => [:edit,:new]

  def show
    @reseller_tier = ResellerTier.general.find_by_id(params[:id])
    if @reseller_tier.blank? and current_user
      tier = current_user.ssl_account.reseller.reseller_tier if current_user.ssl_account.reseller
      @reseller_tier = tier if tier == ResellerTier.find_by_id(params[:id])
    end
    not_found and return if @reseller_tier.blank?
  end

  def show_popup
    @reseller_tier = ResellerTier.find(params[:id])
    @popup = true
    render :action=>'show', :layout=>"tier_pricing_popup"
  end

  def index
  end

  def edit
  end

  def new
  end

end
