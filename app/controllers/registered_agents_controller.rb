class RegisteredAgentsController < ApplicationController
  before_action :require_user
  before_action :find_ssl_account
  before_action :set_row_registered_agent_page, only: [:index, :search]
  before_action :set_row_managed_certificate_page, only: [:managed_certificates, :search_managed_certificates, :remove_managed_certificates]

  def index
    @registered_agents = @ssl_account.registered_agents.paginate(@p)

    respond_to do |format|
      format.html { render :action => :index }
      format.xml  { render :xml => @registered_agents }
    end
  end

  def search
    index
  end

  def show
    @registered_agent = @ssl_account.registered_agents.where(id: params[:id]).first
  end

  def update
    registered_agent = @ssl_account.registered_agents.find(params[:id])
    registered_agent.update_attribute(:friendly_name, params[:friendly_name]) if registered_agent

    redirect_to registered_agents_path(ssl_slug: @ssl_slug)
  end

  def remove_agents
    agent_ids = params[:remove_agents]

    unless agent_ids.blank?
      @ssl_account.registered_agents.where(id: agent_ids).destroy_all
    end

    flash[:notice] = "Selected registered agents has been removed successfully."
    redirect_to registered_agents_path(ssl_slug: @ssl_slug)
  end

  def managed_certificates
    @registered_agent = @ssl_account.registered_agents.where(id: params[:id]).first
    @managed_certificates = @registered_agent.managed_certificates.paginate(@p) if @registered_agent

    respond_to do |format|
      format.html { render :action => :managed_certificates }
    end
  end

  def search_managed_certificates
    managed_certificates
  end

  def remove_managed_certificates
    registered_agent = @ssl_account.registered_agents.find(params[:id])
    registered_agent.managed_certificates.where(id, params[:remove_managed_certs]).destroy_all

    managed_certificates
  end

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

  private

    def set_row_registered_agent_page
      preferred_row_count = current_user.preferred_registered_agent_row_count
      @per_page = params[:ra_per_page] || preferred_row_count.or_else("10")
      RegisteredAgent.per_page = @per_page if RegisteredAgent.per_page != @per_page

      if @per_page != preferred_row_count
        current_user.preferred_registered_agent_row_count = @per_page
        current_user.save(validate: false)
      end

      @p = {page: (params[:page] || 1), per_page: @per_page}
    end

    def set_row_managed_certificate_page
      preferred_row_count = current_user.preferred_managed_certificate_row_count
      @per_page = params[:mc_per_page] || preferred_row_count.or_else("10")
      ManagedCertificate.per_page = @per_page if ManagedCertificate.per_page != @per_page

      if @per_page != preferred_row_count
        current_user.preferred_managed_certificate_row_count = @per_page
        current_user.save(validate: false)
      end

      @p = {page: (params[:page] || 1), per_page: @per_page}
    end
end