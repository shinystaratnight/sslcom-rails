require 'rails_helper'

RSpec.describe 'Authentications', type: :feature do
  let!(:user) { create(:user, :owner) }
  let!(:super_user) {create(:user, :super_user)}
  let!(:login_page) {LoginPage.new}

  before do
    User.any_instance.stubs(:authenticated_avatar_url).returns('https://github.blog/wp-content/uploads/2012/03/codercat.jpg?fit=896%2C896')
  end

  it 'logins in user who registers automatically', js: true do
    registering = attributes_for(:user, :owner)
    visit login_path
    click_on 'Create a new account'
    fill_in 'user_login', with: registering[:login]
    fill_in 'user_email', with: registering[:email]
    fill_in 'user_password', with: registering[:password]
    fill_in 'user_password_confirmation', with: registering[:password_confirmation]
    find('input[name="tos"]').click
    find('input[alt="Register"]').click
    expect(page).to have_content('SSL.com Customer Dashboard')
  end

  it 'allows existing user to login and logout', js: true do
    visit login_path
    login_page.login_with(user)
    expect(page).to have_content("username: #{user.login}")
  end

  it 'fails gracefully when attempting to reset password with nonexistent login', js: true do
    visit new_password_reset_path
    fill_in 'login', with: 'nonexistent'
    find('.password_resets_btn').click
    expect(page).to have_content 'No user was found with that login'
  end

  it 'allows existing user to reset password using login', js: true do
    visit new_password_reset_path
    fill_in 'login', with: user.login
    find('.password_resets_btn').click
    expect(page).to have_content 'Customer login'
  end

  it 'allows existing user to reset password using email', js: true do
    visit new_password_reset_path
    fill_in 'email', with: user.email
    find('.password_resets_btn').click
    expect(page).to have_content 'Customer login'
  end

  it 'fails gracefully when attempting to reset a password with nonexistent email', js: true do
    visit new_password_reset_path
    fill_in 'email', with: 'nonexistent@ssl.com'
    find('.password_resets_btn').click
    expect(page).to have_content 'No user was found with that email'
  end

  it 'requires Duo 2FA when logging in as super_user', js: true do
    as_user(create(:user, :super_user)) do
      expect(page).to have_content 'Duo 2-factor authentication setup'
    end
  end

  xit 'allows sysadmin to login as another user', js: true do
    other = create(:user)
    as_user(create(:user, :sys_admin)) do
      click_on 'Users'
      first('td.dropdown').click
      find('a', text: 'login as').click
      expect(page).to have_content("username: #{other.login}")
    end
  end

  xit 'disallows sysadmin to view "Send to SSL.com CA" page', js: true do
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
end
