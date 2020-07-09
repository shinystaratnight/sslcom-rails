class LoginPage < SitePrism::Page
  set_url '/'

  element :login, '#user_session_login'
  element :password, '#user_session_password'
  element :next, '#btn_login'

  expected_elements :login, :password, :next

  def login_with(user)
    self.login.set user.login
    self.password.set user.password
    self.next.click
    self.wait_until_login_invisible
  end
end
