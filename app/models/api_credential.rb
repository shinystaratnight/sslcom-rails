class ApiCredential < ApplicationRecord
  belongs_to :ssl_account

  validates :account_key, :secret_key, presence: true, length: { minimum: 6 }

  after_initialize do
    if new_record?
      self.account_key ||= SecureRandom.hex(6)
      self.secret_key  ||= SecureRandom.base64(10)
      self.hmac_key ||= SecureRandom.base64(32)
    elsif self.hmac_key.blank?
      self.hmac_key ||= SecureRandom.base64(32)
    end
    save
  end

  def reset_secret_key
    update_attribute :secret_key, SecureRandom.base64(10)
  end

  def set_role_ids(role_ids)
    self.roles = role_ids.to_json
  end

  def role_ids
    roles.nil? ? nil : (JSON.parse roles)
  end
end
