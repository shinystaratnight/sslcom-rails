class ApiCredential < ActiveRecord::Base
  belongs_to :ssl_account

  validates :account_key, :secret_key, presence: true, length: {minimum: 6}
  # validates :ssl_account, presence: true, on: :create

  after_initialize do
    if new_record?
      self.account_key ||= SecureRandom.hex(6)
      self.secret_key  ||= SecureRandom.base64(10)
      self.hmac ||= SecureRandom.base64(32)
    end
  end

  def reset_secret_key
    update_attribute :secret_key, SecureRandom.base64(10)
  end

  def set_role_ids role_ids
    self.roles = role_ids.to_json
  end

  def role_ids
    self.roles.nil? ? nil : (JSON.parse self.roles)
  end

  def role_names
    role_names = []
    unless role_ids.nil?
      role_ids.each do |role_id|
        role_names << Role.find(role_id).name
      end
    end
    role_names
  end
end
