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
#  index_ca_api_requests_on_approval_id                              (approval_id)
#  index_ca_api_requests_on_id_and_type                              (id,type)
#  index_ca_api_requests_on_type_and_api_requestable                 (id,api_requestable_id,api_requestable_type,type) UNIQUE
#  index_ca_api_requests_on_type_and_api_requestable_and_created_at  (id,api_requestable_id,api_requestable_type,type,created_at)
#  index_ca_api_requests_on_type_and_username                        (type,username)
#  index_ca_api_requests_on_username_and_approval_id                 (username,approval_id) UNIQUE
#

class ApiSslManagerRequest < CaApiRequest
  attr_accessor :test, :action

  REGISTER = [:ref, :ip_address, :mac_address, :agent, :friendly_name, :workflow_status, :account_key,
              :secret_key, :requester]
  COLLECTION = [:certificates]
  COLLECTIONS = [:common_name, :subject_alternative_names, :effective_date, :expiration_date, :serial, :issuer, :status]
  DELETE = [:ref_list]

  attr_accessor *(REGISTER+DELETE+COLLECTION+COLLECTIONS).uniq

  before_validation(on: :create) do
    ac = api_credential

    if ac.present?
      self.api_requestable = ac.ssl_account
    else
      errors[:login] << missing_account_key_or_secret_key
      false
    end
  end

  def api_credential
    (self.account_key && self.secret_key) ?
        ApiCredential.find_by_account_key_and_secret_key(self.account_key, self.secret_key) : nil
  end

  def find_ssl_managers(search)
    ssl_managers = self.api_requestable.registered_agents
    ssl_managers = ssl_managers.search_with_terms(search) if search

    if ssl_managers
      ssl_managers
    else
      (errors[:ssl_managers] << "SSL Managers not found.")
    end
  end

  def find_managed_certs(ssl_manager_ref, search)
    ssl_manager = self.api_requestable.registered_agents.find_by_ref(ssl_manager_ref)

    if ssl_manager
      managed_certs = search ? ssl_manager.managed_certificates.search_with_terms(search) : ssl_manager.managed_certificates
      if managed_certs
        managed_certs
      else
        (errors[:managed_certificates] << ("Managed Certificates not found for SSL Manager #" + ssl_manager_ref))
      end
    else
      (errors[:ssl_manager] << "SSL Manager not found.")
    end
  end
end
