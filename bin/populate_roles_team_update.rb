#!/usr/bin/env ruby

# Update Roles table and populate users main_ssl_account field:
#
# Update 2 exisitng roles in the roles table:
#
account_admin_role = Role.find_by(name: 'account_admin')
account_admin_role.update(name: 'owner') if account_admin_role

ssl_user_role = Role.find_by(name: 'ssl_user')
ssl_user_role.update(name: 'account_admin') if ssl_user_role
#
# Populate users table: find the first ssl_account user owns and update
# user's main_ssl_account to that id.
#
User.all.each do |user|
  ssl = user.owned_ssl_account
  user.update(main_ssl_account: ssl.id) if ssl && user.main_ssl_account.nil?
end
#
# Create 3 new roles in the roles table.
#
['billing', 'validations', 'installer', 'users_manager'].each do |name|
  Role.create(name: name)
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
# 
# Populate main roles descriptions
# 
Role.find_by(name: 'billing').update(
  description: 'Access to billing tasks for team. Tasks include creating or deleting billing profiles, managing transactions and renewing certificate orders.'
)
Role.find_by(name: 'users_manager').update(
  description: "Manage teams' users. Tasks include inviting users to team, removing, editing roles, disabling and enabling teams' users."
)
Role.find_by(name: 'installer').update(
  description: "Access to completed certificate and site seal, also has the ability to submit initial CSR and rekey/reprocess the certificate."
)
Role.find_by(name: 'validations').update(
  description: "Access to validation tasks for the Team. Tasks include uploading validation documents, selecting the validation method, and other related tasks."
)
Role.find_by(name: 'account_admin').update(
  description: "Access to all tasks related to managing entire account and team except altering user who owns the ssl team."
)

#
# Create 1 new roles in the roles table.
#
Role.create(name: 'individual_certificate')