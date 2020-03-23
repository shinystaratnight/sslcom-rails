module AuthenticationHelper
  def create_user(login = Faker::Internet.username(specifier: 8))
    @current_user = User.create!(
      login: login,
      password: 'generic',
      password_confirmation: 'generic',
      email: Faker::Internet.safe_email
    )
  end

  def login_user
    visit '/login'
    fill_in('login', with: @current_user.login)
    fill_in('password', with: 'generic')
    click_button('Login')
  end

  def logout_user
    session = UserSession.find
    session&.destroy
  end

  def user_session
    @session ||= UserSession.find
  end
end
