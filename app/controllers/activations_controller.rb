class ActivationsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]

  def new
    @user = User.find_using_perishable_token(params[:activation_code], 1.week) || (raise Exception)
    @invite_params = params[:invite]
    flash[:notice] = "Your account has already been activated." if @user.active?
  end

  def create
    @user = User.find(params[:id])
    raise Exception if @user.active?
    if @user.activate!(params)
      assign_ssl_links(@user)
      @user.deliver_activation_confirmation!
      flash[:notice] = "Your account has been activated."
      redirect_to account_url
    else
      @invite_params = params[:invite]
      render action: :new
    end
  end
end
