require "declarative_authorization/maintenance"

class ApiSslManagerCreate < ApiSslManagerRequest
  attr_accessor :status, :reason

  validates :account_key, :secret_key, presence: true
  validates :ip_address, :mac_address, :agent, presence: true

  def create_ssl_manager
    already_registered = RegisteredAgent.where(
        ip_address: self.ip_address,
        mac_address: self.mac_address,
        ssl_account_id: api_requestable.id,
        agent: self.agent
    ).first

    if already_registered
      already_registered.api_status = 'already_registered' if already_registered.workflow_status == "active"
      already_registered.api_status = 'pending'  if already_registered.workflow_status == "pending_registration"

      return already_registered
    else
      @registered_agent = RegisteredAgent.new

      @registered_agent.ip_address = self.ip_address
      @registered_agent.mac_address = self.mac_address
      @registered_agent.agent = self.agent
      @registered_agent.friendly_name = self.friendly_name ? self.friendly_name : self.mac_address
      @registered_agent.ssl_account = api_requestable
      @registered_agent.requester = User.find_by_login(self.requester)
      @registered_agent.requested_at = DateTime.now
      @registered_agent.approver = @registered_agent.requester if Settings.auto_approve_ssl_manager_register
      @registered_agent.approved_at = @registered_agent.requested_at if Settings.auto_approve_ssl_manager_register
      @registered_agent.workflow_status = Settings.auto_approve_ssl_manager_register ? 'active' : 'pending_registration'

      if @registered_agent.save
        Assignment.where(
            ssl_account_id: api_requestable.id,
            role_id: Role.get_role_id([Role::OWNER, Role::ACCOUNT_ADMIN])).map(&:user).uniq.compact.each do |user|
          user.deliver_register_ssl_manager_to_team!(
              @registered_agent.ref,
              api_requestable,
              Settings.auto_approve_ssl_manager_register
          )
        end
      end

      @registered_agent.api_status = Settings.auto_approve_ssl_manager_register ? 'approved' : 'pending'

      return @registered_agent
    end
  end
end
