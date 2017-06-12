class UserSession < Authlogic::Session::Base
  SESSION_KEY="_ssl_com_session_10242016"
  logout_on_timeout true

  after_create do |this_session|
    user = this_session.record
    SystemAudit.create(
        owner:  user,
        target: nil,
        action: "User #{user.login} has logged in from ip address #{user.current_login_ip}",
        notes:  "#{User.get_user_accounts_roles_names(user).to_s}"
    ) if user.active? && !user.is_disabled?
  end

  before_destroy do |this_session|
    user = this_session.record
    SystemAudit.create(
        owner:  user,
        target: nil,
        action: "User #{user.login} has logged out from ip address #{user.current_login_ip}",
        notes:  "#{User.get_user_accounts_roles_names(user).to_s}"
    ) if user.active? && !user.is_disabled?
  end
end