class BillingProfilesController < ApplicationController
  include ApplicationHelper, OrdersHelper
  #ssl_required :new
  #helper :profile

  respond_to :json
  
  before_filter :login_required, :only => [:new, :create]

  def destroy
    @bp=BillingProfile.find(params[:id])
    @bp.destroy
    respond_with @bp
  end

end