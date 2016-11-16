#!/usr/bin/env ruby

# populate joint "ssl_account_id" attribute for 2 joint tables:
#
# update assignments table
#
Assignment.all.each do |a|
  user = User.find_by(id: a.user_id)
  if user && user.ssl_account_id
    a.update_attribute(:ssl_account_id, user.ssl_account_id)
  end
end
#
# populate ssl_account_users table 
#
users = User.all.map{|u|{user_id: u.id, ssl_account_id: u.ssl_account_id}}
SslAccountUser.create(users)
# 
# populate default_ssl_account attribute for users table
# 
User.all.each do |u|
  unless u.default_ssl_account
    if u.ssl_account_id
      u.update_attribute(:default_ssl_account, u.ssl_account_id)
    end
  end
end
# 
# Roles table, convert/update "customer" role to "account_admin" role
#
Role.find_by(name: 'customer').update(name: 'account_admin')
#
# Roles table, add new role "ssl_user", will be used as default for invited users.
#
Role.create(name: 'ssl_user')
#
# ssl_account_users table, set new "approved" attr to TRUE for all existing users.
#
SslAccountUser.update_all(approved: true)

User.find_each{|u|
  unless u.roles_for_account(u.ssl_account).include?(Role.find_by(name: 'account_admin').id)
    u.assignments.create(ssl_account_id: u.default_ssl_account, role_id: Role.find_by(name: 'account_admin').id)
  end
}

