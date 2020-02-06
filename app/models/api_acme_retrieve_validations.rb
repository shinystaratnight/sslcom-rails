# frozen_string_literal: true

class ApiAcmeRetrieveValidations < ApiAcmeRequest
  extend Memoist

  before_validation(on: :create) do
    if certificate_order.nil?
      errors[:certificate_order_id] << "certificate order not found with id #{certificate_order_id}"
      false
    elsif ac = api_credential
      self.api_requestable = ac.ssl_account
    else
      errors[:credential] << 'invalid credentials'
      false
    end
  end

  def api_credential
    return nil unless account_key && secret_key

    @api_credential = ApiCredential.find_by(account_key: account_key, secret_key: secret_key, acme_acct_pub_key_thumbprint: acme_acct_pub_key_thumbprint)
  end

  def certificate_order
    return nil unless certificate_order_id

    @certificate_order = CertificateOrder.find(certificate_order_id)
  end
  memoize :api_credential
end
