# frozen_string_literal: true

module SessionHelper
  def login_as(user, _cookies = nil)
    activate_authlogic
    UserSession.create(user, true)
    Authorization.current_user = user
  end
end
