class ResellerTiersController < ApplicationController
  before_filter :require_user, :only => [:edit,:new]
  before_filter :require_admin, :only => [:edit,:new]

  def show
    @reseller_tier = ResellerTier.find(params[:id])
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
