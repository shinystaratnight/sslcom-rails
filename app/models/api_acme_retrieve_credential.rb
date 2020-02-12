# frozen_string_literal: true

class ApiAcmeRetrieveCredential < ApiAcmeRequest
  extend Memoist

  validates :account_key, :secret_key, presence: true

  before_validation(on: :create) do
    ac = api_credential

    if ac.blank?
      errors[:credential] << invalid_api_credentials
      false
    else
      self.api_requestable = ac.ssl_account
    end
  end

  def api_credential
    return nil unless account_key && secret_key && acme_acct_pub_key_thumbprint

    ApiCredential.find_by(account_key: account_key, secret_key: secret_key, acme_acct_pub_key_thumbprint: acme_acct_pub_key_thumbprint)
  end
  memoize :api_credential
end
