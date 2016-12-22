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

  def initialize_roles
    create_reminder_triggers
    create_roles
    set_common_roles
  end

  def initialize_certificates
    create(:certificate, :basicssl)
    create(:certificate, :evssl)
    create(:certificate, :uccssl)
    create(:certificate, :wcssl)    
  end

  def create_and_approve_user(invited_ssl_acct, login=nil)
    new_user = login.nil? ? create(:user, :account_admin) : create(:user, :account_admin, login: login)
    new_user.ssl_accounts << invited_ssl_acct
    new_user.set_roles_for_account(invited_ssl_acct, @ssl_user_role)
    new_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
    new_user
  end

  def approve_user_for_account(invited_ssl_acct, invited_user)
    invited_user.ssl_accounts << invited_ssl_acct
    invited_user.set_roles_for_account(invited_ssl_acct, @ssl_user_role)
    invited_user.send(:approve_account, ssl_account_id: invited_ssl_acct.id)
    invited_user
  end
end
