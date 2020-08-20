class ApiAcmeRetrieveHmac < ApiAcmeRequest
  extend Memoist

  validates :hmac_key, presence: true

  before_validation(on: :create) do
    ac = api_credential

    if ac.blank?
      errors[:credential] << 'hmac_key not found or wrong hmac_key'
      false
    end
  end

  def api_credential
    self.hmac_key ? ApiCredential.find_by_hmac_key(self.hmac_key) : nil
  end
  memoize :api_credential
end
