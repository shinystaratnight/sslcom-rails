class ApiAcmeRetrieveHmac < ApiAcmeRequest
  extend Memoist

  validates :hmac, presence: true

  before_validation(on: :create) do
    ac = api_credential

    if ac.blank?
      errors[:credential] << "hamc not found or wrong hmac"
      false
    end
  end

  def api_credential
    self.hmac ? ApiCredential.find_by_hmac(self.hmac) : nil
  end
  memoize :api_credential
end