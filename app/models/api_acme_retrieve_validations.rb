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
