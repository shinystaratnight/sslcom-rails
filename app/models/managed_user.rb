class ManagedUser < User
  self.table_name = 'users'
  
  # 
  # Teams where user does not have ANY roles for user management.
  # 
  def total_teams_cannot_manage_users(user_id=nil)
    user = user_id ? User.find(user_id) : self
    user.ssl_accounts - user.assignments.where(role_id: Role.cannot_be_managed)
      .map(&:ssl_account).uniq.compact
  end
end
