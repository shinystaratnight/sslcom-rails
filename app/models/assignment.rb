class Assignment < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :role
  belongs_to  :ssl_account
end
