class ApiAcmeRequest < CaApiRequest
  extend Memoist
  attr_accessor :test, :action

  ACCESSORS = [:account_key, :secret_key, :debug]

  attr_accessor *(ACCESSORS).uniq

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
  memoize :api_credential
end