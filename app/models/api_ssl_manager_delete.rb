require "declarative_authorization/maintenance"

class ApiSslManagerDelete < ApiSslManagerRequest
  attr_accessor :status

  validates :account_key, :secret_key, presence: true
  validates :ref_list, presence: true

  def delete_ssl_manager
    failed_ref_list = []
    status = ""

    self.ref_list.each do |ref|
      registered_agent = api_requestable.registered_agents.find_by_ref(ref)
      destroyed = registered_agent.destroy if registered_agent
      failed_ref_list << ref unless destroyed
    end

    if failed_ref_list.size == 0
      status = "Successfully deleted SSL Managers."
    else
      status = "It has been failed to delete SSL Manager(s) what ref is in '" +
          failed_ref_list.join(', ')  +
          "'. Please try again to delete those SSL Manager(s)."
    end

    status
  end
end
