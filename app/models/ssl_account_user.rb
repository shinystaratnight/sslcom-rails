class SslAccountUser < ApplicationRecord
  belongs_to  :user
  belongs_to  :unscoped_user, foreign_key: :ssl_account_id, class_name: 'UnscopedUser', inverse_of: :ssl_account_users
  belongs_to  :ssl_account

  scope :approved, ->{ where(approved: true, user_enabled: true) }
  scope :is_approved_ssl_account, ->(id){ approved.where(ssl_account_id: id) }
end
