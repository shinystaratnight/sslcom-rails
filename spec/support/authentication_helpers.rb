module AuthenticationHelpers
  def create_user(login = Faker::Internet.username(specifier: 8))
    @current_user = User.create!(
      login: login,
      password: 'Password123!',
      password_confirmation: 'Password123!',
      email: Faker::Internet.safe_email
    )
    @current_user.activate!(user: { password: 'Password123!', password_confirmation: 'Password123!' })
  end

  def login_user
    visit login_path
    fill_in('user_session_login', with: @current_user.login)
    fill_in('user_session_password', with: 'Password123!')
    find('input#btn_login').click
    expect(page).to have_content('SSL.com Customer Dashboard')
  end

  def logout_user
    session = UserSession.find
    session&.destroy
  end

  def user_session
    @session ||= UserSession.find
  end
end
