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
