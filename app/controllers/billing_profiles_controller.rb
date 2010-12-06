class BillingProfilesController < ApplicationController
  include ApplicationHelper, OrdersHelper
  #ssl_required :new
  #helper :profile
  
  before_filter :login_required, :only => [:new, :create]

  def destroy
    BillingProfile.destroy(params[:id])
  end

end