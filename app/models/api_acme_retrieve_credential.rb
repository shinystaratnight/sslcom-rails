class ApiAcmeRetrieveCredential < ApiAcmeRequest
  extend Memoist

  validates :account_key, :secret_key, presence: true

  before_validation(on: :create) do
    if acme_acct_pub_key_thumbprint.blank?
      errors[:parameters] << 'required parameter acme_acct_pub_key_thumbprint missing'
      false
    elsif api_credential.blank?
      errors[:credential] << invalid_api_credentials
      false
    else
      self.api_requestable = api_credential.ssl_account
    end
  end

  def api_credential
    return nil unless account_key && secret_key

    ac = ApiCredential.find_by(account_key: account_key, secret_key: secret_key)
    ac&.update(acme_acct_pub_key_thumbprint: acme_acct_pub_key_thumbprint) if acme_acct_pub_key_thumbprint.present?
    ac
  end
  memoize :api_credential
end
