class RegisteredAgentsController < ApplicationController
  before_action :require_user
  before_action :find_ssl_account

  def approve
    registered_agent = RegisteredAgent.find params[:id]
    if registered_agent.workflow_status == 'active'
      flash[:notice] = "SSL Manager has been already activated by another user."
    else
      registered_agent.workflow_status = 'active'
      registered_agent.approver = current_user
      registered_agent.approved_at = DateTime.now
      registered_agent.save

      flash[:notice] = "SSL Manager has been activated."
    end

    redirect_to account_path(ssl_slug: @ssl_slug)
  end
end