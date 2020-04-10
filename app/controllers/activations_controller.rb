class ActivationsController < ApplicationController
  before_action :require_no_user, :only => [:new, :create]
  rescue_from Exception, :with => :not_found

  def new
    @user = User.find_using_perishable_token(params[:activation_code], 1.week) || (raise Exception)
    @invite_params = params[:invite]
    flash[:notice] = "Your account has already been activated." if @user.active?
  end

  def create
    @user = User.find(params[:id])
    raise Exception if @user.active?
    if @user.activate!(params)
      # Check Code Signing Certificate Order for assign as assignee.
      CertificateOrder.unscoped.search_validated_not_assigned(@user.email).each do |cert_order|
        cert_order.update_attribute(:assignee, @user)
        LockedRecipient.create_for_co(cert_order)
      end

      @user.deliver_activation_confirmation!
      if params[:tos] # Subscriber Agreement checked
        @user.ssl_account.update_column(:epki_agreement, DateTime.now)
      end
      flash[:notice] = "Your account has been activated."
      redirect_to account_path((@user.ssl_account ? @user.ssl_account.to_slug : {}))
    else
      @invite_params = params[:invite]
      render action: :new
    end
  end
end
