class Role < ActiveRecord::Base
  has_many                  :assignments
  has_many                  :users, :through => :assignments
  has_and_belongs_to_many   :permissions
  belongs_to                :ssl_account #as account_role. if specified, then it's a role that is specific to this account. If not specified then it's a global role

  RESELLER = 'reseller'
  CUSTOMER = 'account_admin'
  VETTER = 'vetter'
end
