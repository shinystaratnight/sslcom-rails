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
      errors[:credential] << 'account_key not found or wrong secret_key'
      false
    end
  end

  def api_credential
    return nil unless account_key && secret_key

    ApiCredential.find_by(account_key: account_key, secret_key: secret_key)
  end

  def certificate_order
    return nil unless certificate_order_id

    CertificateOrder.find(certificate_order_id)
  end
  memoize :api_credential
end
