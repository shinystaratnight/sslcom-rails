class DuoAccount < ApplicationRecord
  belongs_to :ssl_account

  validates :duo_akey, length: { minimum: 40 }
  attr_encrypted :duo_ikey, :duo_skey, :duo_akey, :duo_hostname, :key => Rails.application.secrets.secret_key_base,algorithm: 'aes-256-cbc', :mode => :per_attribute_iv_and_salt, insecure_mode: true

  after_initialize do
    if new_record?
      self.duo_akey  ||= SecureRandom.base64(40)
    end
  end

  def reset_secret_key
    update_attribute :duo_akey, SecureRandom.base64(40)
  end
end
