module AuthenticationHelpers
  def as_user(user)
    visit '/'
    Capybara.reset_sessions!
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: user.password
    find('#btn_login').click
    yield

    visit logout_path
  end
end
