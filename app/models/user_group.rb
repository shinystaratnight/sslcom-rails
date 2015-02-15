class UserGroup < ActiveRecord::Base
  belongs_to :ssl_account
  has_and_belongs_to_many :users
  easy_roles :roles
end