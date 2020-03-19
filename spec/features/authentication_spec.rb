require 'rails_helper'

RSpec.feature 'Authentications', type: :feature do
  before(:all) do
    initialize_roles
    initialize_triggers
    initialize_server_software
    initialize_certificates
  end

  let!(:user) { create(:user, :owner) }

  before(:each) do
    SystemAudit.stubs(:create).returns(true)
    stub_paperclip(User)
    User.any_instance.stubs(:authenticated_avatar_url).returns('https://github.blog/wp-content/uploads/2012/03/codercat.jpg?fit=896%2C896')
  end

  it 'logins in user who registers automatically', js: true do
    visit login_path
    click_on 'Create a new account'
    fill_in 'user_login', with: 'cypress'
    fill_in 'user_email', with: 'cypress@ssl.com'
    fill_in 'user_password', with: 'Testing_ssl+1'
    fill_in 'user_password_confirmation', with: 'Testing_ssl+1'
    find('input[name="tos"]').click
    find('input[alt="Register"]').click
    expect(page).to have_content('SSL.com Customer Dashboard')
  end

  it 'allows existing user to login and logout', js: true do
    user.deliver_auto_activation_confirmation!
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    expect(page).to have_content("username: #{user.login}")
  end

  it 'allows an existing user to login', js: true do
    user = create(:user, :owner)
    user.deliver_auto_activation_confirmation!
    visit login_path
    fill_in 'user_session_login', with: user.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('input[alt="submit"]').click
    expect(page).to have_content("username: #{user.login}")
  end
end

# it('allows user to register and login', function () {
#   cy.visit('/user_session/new')
#   cy.contains('Create a new account').click()

#   cy.get('form').within(($form) => {
#     cy.get('input[name="user[login]"]').type('cypress')
#     cy.get('input[name="user[email]"]').type('cypress@test.ssl.com')
#     cy.get('input[name="user[password]"]').type('Testing_ssl+1')
#     cy.get('input[name="user[password_confirmation]"]').type('Testing_ssl+1')
#     cy.get('input[name="tos"]').click()
#     cy.root().submit()
#   })

#   cy.contains('SSL.com Customer Dashboard')
#   cy.visit('/logout')
# })

# it('allows existing user to login and logout', function () {
#   cy.get('form').within(($form) => {
#     cy.get('input[name="user_session[login]"]').type('cypress')
#     cy.get('input[name="user_session[password]"]').type('Testing_ssl+1')
#     cy.root().submit()
#   })

#   cy.get('#content').contains('SSL.com Customer Dashboard')

#   cy.contains('Logout').click()

#   cy.contains('Customer login')
#   cy.visit('/logout')
# })

# it('fails gracefully when attempting to reset password with nonexistent login', function () {
#   cy.visit('/password_resets/new')

#   cy.get('form').within(($form) => {
#     cy.get('input[name="login"]').type('nonexistent')
#   })
#   cy.get('.password_resets_btn').click()
#   cy.contains('No user was found with that login')
# })

# it('allows existing user to reset password using login', function () {
#   cy.appFactories([
#     ['create', 'user', {login: 'token'}]
#   ])
#   cy.visit('/password_resets/new')

#   cy.get('form').within(($form) => {
#     cy.get('input[name="login"]').type('token')
#   })
#   cy.get('.password_resets_btn').click()
#   cy.contains('Customer login')
# })

# it('allows existing user to reset password using email', function () {
#   cy.appFactories([
#     ['create', 'user', {email: 'cartman@gmail.com'}]
#   ])
#   cy.visit('/password_resets/new')

#   cy.get('form').within(($form) => {
#     cy.get('input[name="email"]').type('cartman@gmail.com')
#   })
#   cy.get('.password_resets_btn').click()
#   cy.contains('Customer login')
# })

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

  xit 'requires Duo 2FA when logging in as super_user', js: true do
    sys_admin = create(:user, :super_user)
    visit login_path
    fill_in 'user_session_login', with: sys_admin.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    expect(page).to have_content 'Duo'
  end

  xit 'allows sysadmin to login as another user', js: true do
    other = create(:user)
    admin = create(:user, :sys_admin)
    admin.make_admin
    visit login_path
    fill_in 'user_session_login', with: admin.login
    fill_in 'user_session_password', with: 'Testing_ssl+1'
    find('#btn_login').click
    click_on 'Users'
    first('td.dropdown').click
    find('a', text: 'login as').click
    expect(page).to have_content("username: #{other.login}")
  end
end
