class ApiSslManagerRequest < CaApiRequest
  attr_accessor :test, :action

  REGISTER = [:ref, :ip_address, :mac_address, :agent, :friendly_name, :workflow_status, :account_key,
              :secret_key, :requester]
  COLLECTION = [:certificates]

  attr_accessor *(REGISTER+COLLECTION).uniq

  before_validation(on: :create) do
    ac = api_credential

    unless ac.blank?
      self.api_requestable = ac.ssl_account
    else
      errors[:login] << "account_key not found or wrong secret_key"
      false
    end
  end

  def api_credential
    (self.account_key && self.secret_key) ?
        ApiCredential.find_by_account_key_and_secret_key(self.account_key, self.secret_key) : nil
  end
end