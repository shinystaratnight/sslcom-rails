# == Schema Information
#
# Table name: ca_api_requests
#
#  id                   :integer          not null, primary key
#  api_requestable_type :string(191)
#  ca                   :string(255)
#  certificate_chain    :text(65535)
#  method               :string(255)
#  parameters           :text(65535)
#  raw_request          :text(65535)
#  request_method       :text(65535)
#  request_url          :text(65535)
#  response             :text(16777215)
#  type                 :string(191)
#  username             :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  api_requestable_id   :integer
#  approval_id          :string(255)
#
# Indexes
#
#  index_ca_api_requests_on_api_requestable                          (api_requestable_id,api_requestable_type)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

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
