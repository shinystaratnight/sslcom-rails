class ApiAcmeRetrieveValidations < ApiAcmeRequest
  extend Memoist

  before_validation(on: :create) do
    if api_credential.nil?
      errors[:credential] << I18n.t('error.invalid_api_credentials')
      false
    elsif certificate_order.nil?
      errors[:certificate_order_ref] << "certificate order #{certificate_order_ref} not found"
      false
    else
      self.api_requestable = api_credential.ssl_account
    end
  end

  def api_credential
    return nil unless account_key && secret_key

    @api_credential = ApiCredential.find_by(account_key: account_key, secret_key: secret_key)
  end
  memoize :api_credential

  def certificate_order
    return nil unless certificate_order_ref && api_credential

    @certificate_order = certificate_orders.find_by(ref: certificate_order_ref)
  end
  memoize :certificate_order

  private

  def certificate_orders
    api_credential.ssl_account.certificate_orders.includes(certificate_contents: [:certificate_names])
  end
end
