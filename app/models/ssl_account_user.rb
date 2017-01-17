class SslAccountUser < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :unscoped_user, foreign_key: :ssl_account_id, class_name: "UnscopedUser"
  belongs_to  :ssl_account

  scope :approved, ->{where{(approved == true) & (user_enabled == true)}}
end
