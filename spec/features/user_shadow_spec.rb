require 'rails_helper'

RSpec.describe 'User Assign Roles', type: :feature, js: true do
  let!(:user_owner) {create(:user, :owner)}
  let!(:user_sysadmin) {create(:user, :sys_admin)}
  let!(:user_super_user) {create(:user, :super_user)}
  let!(:login_page) {LoginPage.new}
  let!(:header) {Header.new}
  let!(:users_page) {UsersPage.new}
  let!(:search) {Search.new}

  it 'User with sysadmin role can log in as any user without sysadmin or super_user role' do
    login_page.load
    login_page.login_with(user_sysadmin)
    header.wait_until_logout_visible(wait: 5)
    users_page.load
    search.wait_until_search_field_visible(wait: 5)
    search.search_field.set user_owner.email
    users_page.search_button.click
    all('tr').last.click
    click_link "login as #{user_owner.login}"
    expect(page).to have_content('Successfully logged in.')
  end

  it 'User with super_user role can log in as any user without super_user role' do
    login_page.load
    login_page.login_with(user_super_user)
    expect(page).to have_content('MY ACCOUNT')
    users_page.load
    search.wait_until_search_field_visible(wait: 5)
    search.search_field.set user_owner.email
    users_page.search_button.click
    all('tr').last.click
    click_link "login as #{user_owner.login}"
    expect(page).to have_content('Duo 2-factor authentication setup.')
  end
end