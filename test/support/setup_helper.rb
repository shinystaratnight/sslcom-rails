module SetupHelper
  def create_roles
    roles = [
      Role::RESELLER,
      Role::ACCOUNT_ADMIN,
      Role::VETTER,
      Role::SSL_USER,
      Role::SYS_ADMIN,
      Role::SUPER_USER
    ]
    unless Role.count == roles.count
      roles.each { |role_name| Role.create(name: role_name) }
    end
  end

  def create_reminder_triggers
    unless ReminderTrigger.count == 5
      (1..5).to_a.each { |i| ReminderTrigger.create(id: i, name: i) }
    end
  end

  def set_common_roles
    @all_roles       = [Role.get_role_id(Role::ACCOUNT_ADMIN), Role.get_role_id(Role::SSL_USER)]
    @ssl_user_role   = [Role.get_role_id(Role::SSL_USER)]
    @acct_admin_role = [Role.get_role_id(Role::ACCOUNT_ADMIN)]
  end
end
