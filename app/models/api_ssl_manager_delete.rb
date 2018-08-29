require "declarative_authorization/maintenance"

class ApiSslManagerDelete < ApiSslManagerRequest
  attr_accessor :message

  validates :account_key, :secret_key, presence: true
  validates :ref_list, presence: true

  def delete_ssl_manager
    failed_ref_list = []
    message = ""

    self.ref_list.each do |ref|
      destroyed = api_requestable.registered_agents.find_by_ref(ref).destroy
      failed_ref_list << ref unless destroyed
    end

    if failed_ref_list.size == 0
      message = "Successfully deleted SSL Managers."
    else
      message = "It has been failed to delete SSL Manager what ref is '" +
          failed_ref_list.join(', ')  +
          "'. Please try again."
    end

    message
  end
end