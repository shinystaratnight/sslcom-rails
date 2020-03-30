# require 'rails_helper'
#
# describe 'remove user from account' do
#   before do
#     initialize_roles
#     @current_owner       = create(:user, :owner)
#     @invited_ssl_acct    = @current_owner.ssl_account
#     @existing_user_email = 'exist_user@domain.com'
#     @existing_user       = create(:user, :owner, email: @existing_user_email)
#     @existing_ssl_acct   = @existing_user.ssl_account
#     @existing_user.ssl_accounts << @invited_ssl_acct
#     @existing_user.set_roles_for_account(@invited_ssl_acct, @acct_admin_role)
#     @existing_user.send(:approve_account, ssl_account_id: @invited_ssl_acct.id)
#     @existing_user.activate!(
#       user: {login: 'existing_user', password: 'Testing_ssl+1', password_confirmation: 'Testing_ssl+1'}
#     )
#   end
#
#   describe 'owner' do
#     before do
#       assert_equal 2, @existing_user.ssl_accounts.count
#       assert_equal 2, @existing_user.roles.count
#       assert       @current_owner.user_exists_for_account?(@existing_user_email)
#
#       login_as(@current_owner, self.controller.cookies)
#       visit account_path
#       click_on 'Users'
#       first('td', text: @existing_user_email).click
#       click_on 'remove user from this account'
#       sleep 1 # allow time to generate notification email
#     end
#
#     it 'user removed from users index' do
#       assert_match users_path, current_path
#       assert page.has_no_content? @existing_user_email
#       assert page.has_no_content? @existing_user.login
#     end
#     it 'owner receives removed_from_account_notify_admin email' do
#       assert_equal    2, email_total_deliveries
#       assert_match    'You have removed user from SSL.com account', email_subject
#       assert_match    @current_owner.email, email_to
#       assert_match    'noreply@ssl.com', email_from
#       assert_includes email_body, "user #{@existing_user_email} has been removed from your SSL.com account."
#     end
#     it 'removed user receives removed_from_account email' do
#       assert_equal    2, email_total_deliveries
#       assert_match    'You have been removed from SSL.com account', email_subject(:first)
#       assert_match    @existing_user_email, email_to(:first)
#       assert_match    @current_owner.email, email_from(:first)
#       assert_includes email_body(:first), "You have been removed from SSL.com account #{@invited_ssl_acct.acct_number}."
#     end
#     it 'remove association to ssl account and roles' do
#       assert_equal 1, @existing_user.ssl_accounts.count
#       assert_equal 1, @existing_user.roles.count
#       assert_equal @existing_ssl_acct.id, @existing_user.default_ssl_account
#       assert_equal @owner_role, @existing_user.roles.ids
#       refute       @current_owner.user_exists_for_account?(@existing_user_email)
#     end
#   end
#
#   describe 'sysadmin' do
#     before do
#       @sysadmin = create(:user, :sysadmin)
#       login_as(@sysadmin, update_cookie(self.controller.cookies, @sysadmin))
#       visit account_path
#       click_on 'Users'
#       first('td', text: @existing_user_email).click
#       click_on 'leave'
#       page.driver.browser.switch_to.alert.accept # accept prompt
#       sleep 1 # allow time to generate notification email
#     end
#
#     it 'removed user receives removed_from_account email' do
#       assert_equal    1, email_total_deliveries
#       assert_match    'You have been removed from SSL.com account', email_subject(:first)
#       assert_match    @existing_user_email, email_to(:first)
#       assert_match    @sysadmin.email, email_from(:first)
#       assert_includes email_body(:first), "You have been removed from SSL.com account #{@invited_ssl_acct.acct_number}."
#     end
#     it 'remove association to ssl account and roles' do
#       assert_equal 1, @existing_user.ssl_accounts.count
#       assert_equal 1, @existing_user.roles.count
#       assert_equal @existing_ssl_acct.id, @existing_user.default_ssl_account
#       assert_equal @owner_role, @existing_user.roles.ids
#       refute       @current_owner.user_exists_for_account?(@existing_user_email)
#     end
#   end
# end
