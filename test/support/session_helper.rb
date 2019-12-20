module SessionHelper
  def login_as(user, cookies=nil)
    activate_authlogic
    UserSession.create(user, true)
    Authorization.current_user = user
  end
end
