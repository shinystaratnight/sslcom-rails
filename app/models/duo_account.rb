# == Schema Information
#
# Table name: duo_accounts
#
#  id                          :integer          not null, primary key
#  duo_akey                    :string(255)
#  duo_hostname                :string(255)
#  duo_ikey                    :string(255)
#  duo_skey                    :string(255)
#  encrypted_duo_akey          :string(255)
#  encrypted_duo_akey_iv       :string(255)
#  encrypted_duo_akey_salt     :string(255)
#  encrypted_duo_hostname      :string(255)
#  encrypted_duo_hostname_iv   :string(255)
#  encrypted_duo_hostname_salt :string(255)
#  encrypted_duo_ikey          :string(255)
#  encrypted_duo_ikey_iv       :string(255)
#  encrypted_duo_ikey_salt     :string(255)
#  encrypted_duo_skey          :string(255)
#  encrypted_duo_skey_iv       :string(255)
#  encrypted_duo_skey_salt     :string(255)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  ssl_account_id              :integer
#
# Indexes
#
#  index_duo_accounts_on_ssl_account_id  (ssl_account_id)
#

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
