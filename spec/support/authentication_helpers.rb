module AuthenticationHelpers
  def login_user(user)
    visit login_path
    fill_in('user_session_login', with: user.login)
    fill_in('user_session_password', with: 'Testing_ssl+1')
    find('input#btn_login').click
    expect(page).to have_content('SSL.com Customer Dashboard')
  end
end
