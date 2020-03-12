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
