class LoginPage < SitePrism::Page
  set_url '/login'

  element :login, '#user_session_login'
  element :password, '#user_session_password'
  element :next_button, '#btn_login'

  expected_elements :login, :password, :next

  def login_with(user)
    login.set user.login
    password.set user.password
    next_button.click
    wait_until_login_invisible
  end
end
