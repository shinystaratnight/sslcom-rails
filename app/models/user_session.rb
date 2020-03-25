class UserSession < Authlogic::Session::Base
  SESSION_KEY = '_ssl_com_session_10242016'
  logout_on_timeout true
  # consecutive_failed_logins_limit 1

  after_create do |this_session|
    user = this_session.record
    audit_login(user) if user.active? && !user.is_disabled?
  end

  before_validation do |this_session|
    if User.find_by_login(this_session.login).try('is_system_admins?'.to_sym)
      UserSession.consecutive_failed_logins_limit 5
    else
      UserSession.consecutive_failed_logins_limit 15
    end
  end

  before_destroy do |this_session|
    user = this_session.record
    if user.active? && !user.is_disabled?
      SystemAudit.create(
        owner: user,
        target: nil,
        action: "User #{user.login} has logged out from ip address #{user.current_login_ip}",
        notes: User.get_user_accounts_roles_names(user).to_s
      )
    end
  end

  private

  def audit_login(user)
    SystemAudit.create(
      owner: user,
      target: nil,
      action: "User #{user.login} has logged in from ip address #{user.current_login_ip}",
      notes: User.get_user_accounts_roles_names(user).to_s
    )
  end
end
