# frozen_string_literal: true

# == Schema Information
#
# Table name: api_credentials
#
#  id                           :integer          not null, primary key
#  account_key                  :string(255)
#  acme_acct_pub_key_thumbprint :string(255)
#  hmac_key                     :string(255)
#  roles                        :string(255)
#  secret_key                   :string(255)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  ssl_account_id               :integer
#
# Indexes
#
#  index_api_credentials_on_account_key_and_secret_key    (account_key,secret_key) UNIQUE
#  index_api_credentials_on_acme_acct_pub_key_thumbprint  (acme_acct_pub_key_thumbprint)
#  index_api_credentials_on_ssl_account_id                (ssl_account_id)
#

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

  def role_names
    Role.find(role_ids).map(&:name)
  end
end
