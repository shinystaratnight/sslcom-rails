class SslAccountUser < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :ssl_account
end
