#!/usr/bin/env ruby

#
# Populate users table: find the first ssl_account user owns and update
# user's main_ssl_account to that id.
#
User.all.each do |user|
  ssl = user.owned_ssl_account
  user.update(main_ssl_account: ssl.id) if ssl && user.main_ssl_account.nil?
end
#
# Cleanup roles table:
# If any vestigial role produces zero associations, then delete it from the roles table.
#
vestigial_roles = [
  'vetter',
  'Account Billing',
  'certificates_approver',
  'certificates_manager',
  'prices_restricted',
  'orders_requestor',
  'orders_approver',
  'orders_manager',
  'admin',
  'customer_admin'
]

vestigial_roles.each do |name|
  role = Role.find_by(name: name)
  if role && Assignment.where(role_id: role.id).empty?
    role.destroy
  end
end
