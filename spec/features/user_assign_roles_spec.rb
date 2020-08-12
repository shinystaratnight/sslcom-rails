require 'rails_helper'

RSpec.describe 'User Assign Roles', type: :feature, js: true do
  let!(:user_owner) { create(:user, :owner) }
  let!(:user_sysadmin) { create(:user, :sys_admin) }
  let!(:login_page) {LoginPage.new}
  let!(:header) {Header.new}
  let!(:users_page) {UsersPage.new}
  let!(:search) {Search.new}
  let!(:edit_user_roles_page) {EditUserRolesPage.new}

  it 'User with sysadmin role can assign roles for any user without sysadmin or super_user role' do
    login_page.load
    login_page.login_with(user_sysadmin)
    header.wait_until_logout_visible(wait: 5)
    users_page.load
    search.wait_until_search_field_visible(wait: 5)
    search.search_field.set user_owner.email
    users_page.search_button.click
    all('tr').last.click
    users_page.owner_link.click
    edit_user_roles_page.super_user_checkbox.click
    edit_user_roles_page.select_ssl_account
    first("li[class='select2-results__option']").click
    edit_user_roles_page.submit_button.click
    expect(page).to have_content("#{user_owner.email} roles have been updated for teams:")
  end

  it 'User with super_user role can assign roles for and user without super_user role' do
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
end
