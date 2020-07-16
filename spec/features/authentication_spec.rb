require 'rails_helper'

RSpec.describe 'Authentications', type: :feature do
  let!(:user) { create(:user, :owner) }
  let!(:super_user) {create(:user, :super_user)}
  let!(:login_page) {LoginPage.new}
  let!(:header) {Header.new}
  let!(:registration_page) {RegistrationPage.new}
  let!(:reset_password_page) {ResetPasswordPage.new}

  before do
    User.any_instance.stubs(:authenticated_avatar_url).returns('https://github.blog/wp-content/uploads/2012/03/codercat.jpg?fit=896%2C896')
  end

  it 'logins in user who registers automatically', js: true do
    registering = attributes_for(:user, :owner)
    visit login_path
    click_on 'Create a new account'
    registration_page.login.set registering[:login]
    registration_page.email.set registering[:email]
    registration_page.password.set registering[:password]
    registration_page.password_confirmation.set registering[:password_confirmation]
    registration_page.terms_of_service.click
    registration_page.register.click
    expect(page).to have_content('SSL.com Customer Dashboard')
  end


  scenario 'allows existing user to login and logout' do
    login_page.load
    login_page.login_with(user)
    expect(page).to have_content("username: #{user.login}")
    header.logout.click
    expect(page).to have_content('Successfully logged out.')
  end

  scenario 'fails gracefully when attempting to reset password with nonexistent login' do
    reset_password_page.load
    reset_password_page.login.set 'nonexistent'
    reset_password_page.submit.click
    expect(page).to have_content 'No user was found with that login'
  end

  scenario 'allows existing user to reset password using login' do
    reset_password_page.load
    reset_password_page.login.set user.login
    reset_password_page.submit.click
    expect(page).to have_content 'Customer login'
  end

  scenario 'allows existing user to reset password using email' do
    reset_password_page.load
    reset_password_page.email.set user.email
    reset_password_page.submit.click
    expect(page).to have_content 'Customer login'
  end

  scenario 'fails gracefully when attempting to reset a password with nonexistent email' do
    reset_password_page.load
    reset_password_page.email.set 'nonexistent@ssl.com'
    reset_password_page.submit.click
    expect(page).to have_content 'No user was found with that email'
  end

  scenario 'requires Duo 2FA when logging in as super_user' do
    login_page.load
    login_page.login_with(super_user)
    expect(page).to have_content 'Duo 2-factor authentication setup'
  end

  xit 'disallows sysadmin to view "Send to SSL.com CA" page' do
    other = create(:user)
    as_user(create(:user, :sys_admin)) do
      visit certificate_order_path(ref: "co-10000")
      expect(page).to have_content("username: #{other.login}")
    end
  end

  scenario 'superuser 30 min session logout', authentication: true,  js: true do
    visit login_path
    login_page.login_with(super_user)
    Timecop.travel(Time.current + 30.minutes)
    refresh
    expect(current_url).to include('/user_session/new')
  end

  context 'when user visited cart' do
    xit 'redirect to cart after login', js: true do
      # Cart checkout
      visit show_cart_orders_path
      find('a#add_items_img').click
      first('img[alt="Buy sm bl"]').click
      find('#next_submit').click
      find('a#checkout_img').click
      # Login
      fill_in 'user_session_login', with: user.login
      fill_in 'user_session_password', with: user.password
      find('#btn_login').click

      expect(page).to have_current_path new_order_path
    end
  end
end
