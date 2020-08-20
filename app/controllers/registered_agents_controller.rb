class RegisteredAgentsController < ApplicationController
  before_action :require_user
  before_action :find_ssl_account
  before_action :global_set_row_page, only: [:index, :search, :managed_certificates, :search_managed_certificates, :remove_managed_certificates]

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
    @registered_agent = @ssl_account.registered_agents.find_by_ref(params[:id])
  end

  def update
    registered_agent = @ssl_account.registered_agents.find_by_ref(params[:id])
    registered_agent.update_attribute(:friendly_name, params[:friendly_name]) if registered_agent

    redirect_to registered_agents_path(ssl_slug: @ssl_slug)
  end

  def remove_agents
    agent_ids = params[:registered_agent_check]

    unless agent_ids.blank?
      @ssl_account.registered_agents.where(id: agent_ids).destroy_all
    end

    flash[:notice] = "Selected registered agents has been removed successfully."
    redirect_to registered_agents_path(ssl_slug: @ssl_slug)
  end

  def managed_certificates
    @registered_agent = @ssl_account.registered_agents.find_by_ref(params[:id])
    @managed_certificates = @registered_agent.managed_certificates.paginate(@p) if @registered_agent

    respond_to do |format|
      format.html { render :action => :managed_certificates }
    end
  end

  def search_managed_certificates
    managed_certificates
  end

  def remove_managed_certificates
    registered_agent = @ssl_account.registered_agents.find_by_ref(params[:id])
    registered_agent.managed_certificates.where(id: params[:remove_managed_certs]).destroy_all

    managed_certificates
  end

  def approve_ssl_managers
    agent_ids = params[:registered_agent_check]

    unless agent_ids.blank?
      @ssl_account.registered_agents.where(id: agent_ids).each do |agent|
        next if agent.workflow_status == 'active'

        agent.workflow_status = 'active'
        agent.approver = current_user
        agent.approved_at = DateTime.now
        agent.save
      end

      flash[:notice] = "Selected SSL Manager(s) has been activated."
    end

    redirect_to registered_agents_path(ssl_slug: @ssl_slug) and return
  end

  def approve_ssl_manager
    returnObj = {}
    registered_agent = @ssl_account.registered_agents.where(id: params[:registered_agent_id]).first

    if registered_agent
      registered_agent.workflow_status = 'active'
      registered_agent.approver = current_user
      registered_agent.approved_at = DateTime.now
      registered_agent.save
    end

    returnObj['approved_at'] = registered_agent.approved_at.strftime("%b %d, %Y")

    render :json => returnObj
  end

  def approve
    registered_agent = RegisteredAgent.find_by_ref params[:id]

    if registered_agent
      agent_ssl_account = registered_agent.ssl_account

      if current_user.ssl_accounts.find(agent_ssl_account)
        if current_user.role_symbols(agent_ssl_account).include?((Role::OWNER).to_sym) ||
            current_user.role_symbols(agent_ssl_account).include?((Role::ACCOUNT_ADMIN).to_sym)
          if registered_agent.workflow_status == 'active'
            flash[:notice] = "SSL Manager has been already activated by another user."
          else
            registered_agent.workflow_status = 'active'
            registered_agent.approver = current_user
            registered_agent.approved_at = DateTime.now
            registered_agent.save

            flash[:notice] = "SSL Manager has been activated."
          end
        else
          flash[:error] = "You have no permission to approve this SSL Manager."
        end
      else
        flash[:error] = "It is allowed to access to this SSL Manager by only team members."
      end
    else
      flash[:error] = "It does not exist SSL Manager (#" + params[:id] + ")"
    end

    redirect_to account_path(ssl_slug: @ssl_slug)
  end

end
