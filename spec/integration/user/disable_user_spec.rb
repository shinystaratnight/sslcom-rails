# require 'rails_helper'
#
# describe 'Disable user' do
#   before do
#     initialize_roles
#     @owner     = create(:user, :owner)
#     @owner_2   = create(:user, :owner)
#     @owner_ssl = @owner.ssl_account
#     @sysadmin  = create(:user, :sysadmin)
#     (1..4).to_a.each {|n| create_and_approve_user(@owner_ssl, "account_admin_#{n}")}
#
#     @disable_user     = User.find_by(login: 'account_admin_1')
#     @disable_user_ssl = @disable_user.ssl_account
#     approve_user_for_account(@owner_2.ssl_account, @disable_user)
#     refute @disable_user.is_disabled?(@owner_ssl) # NOT disabled
#     assert_equal 3, @disable_user.get_all_approved_accounts.count
#   end
#
#   describe 'by sysadmin user' do
#     before do
#       login_as(@sysadmin, update_cookie(self.controller.cookies, @sysadmin))
#       visit account_path
#       click_on 'Users'
#       first('td', text: @disable_user.email).click # expand user's row
#       find('#user_status_disabled').set(true)      # check disable radio btn
#       delete_all_cookies
#       click_on 'Logout'
#     end
#
#     describe 'CANNOT access' do
#       it 'ALL associated accounts' do
#         assert_equal 0, @disable_user.get_all_approved_accounts.count
#         assert       @disable_user.is_admin_disabled?
#         login_as(@disable_user, update_cookie(self.controller.cookies, @disable_user))
#
#         @disable_user.ssl_accounts.each do |ssl|
#           visit account_path
#           visit switch_default_ssl_account_user_path(
#             @disable_user, ssl_account_id: ssl.id
#           )
#           assert_match root_path, current_path
#         end
#       end
#     end
#   end
#
#   describe 'by owner' do
#     before do
#       # owner disables user
#       login_as(@owner, self.controller.cookies)
#       visit account_path
#       click_on 'Users'
#       first('td', text: @disable_user.email).click # expand user's row
#       find('#user_status_disabled').set(true)      # check disable radio btn
#       click_on 'Logout'
#       login_as(@disable_user, update_cookie(self.controller.cookies, @disable_user))
#       visit account_path
#     end
#
#     it 'CANNOT access owners account' do
#       assert       @disable_user.is_disabled?(@owner_ssl) # IS disabled
#       assert_equal @disable_user.get_all_approved_accounts.first.id, @disable_user.default_ssl_account
#       assert_equal 2, @disable_user.get_all_approved_accounts.count
#       # cannot swith to owners account
#       visit switch_default_ssl_account_user_path(@disable_user, ssl_account_id: @owner_ssl.id)
#       assert_match root_path, current_path
#       visit account_path
#       page.must_have_content "ssl account information for #{@disable_user.login}"
#       page.must_have_content "account number: #{@disable_user.ssl_account.acct_number}"
#       assert_equal           @disable_user.get_all_approved_accounts.first.id, @disable_user.default_ssl_account
#       assert_equal           2, @disable_user.get_all_approved_accounts.count
#     end
#
#     it 'CAN access their own account' do
#       page.must_have_content "ssl account information for #{@disable_user.login}"
#       page.must_have_content "account number: #{@disable_user.ssl_account.acct_number}"
#       assert_equal           2, @disable_user.get_all_approved_accounts.count
#     end
#
#     it 'CAN access other associated accounts' do
#       # CAN switch to another invited/enabled ssl account of @owner_2
#       visit switch_default_ssl_account_user_path(
#         @disable_user, ssl_account_id: @owner_2.ssl_account.id
#       )
#       @disable_user          = User.find_by(login: 'account_admin_1') # refresh record
#       page.must_have_content "ssl account information for #{@disable_user.login}"
#       page.must_have_content "account number: #{@owner_2.ssl_account.acct_number}"
#       assert_equal           @owner_2.ssl_account.id, @disable_user.default_ssl_account
#     end
#   end
#
#   describe 'other users on disabled users account' do
#     before do
#       @other_user_on_account = User.find_by(login: 'account_admin_2')
#       approve_user_for_account(@disable_user.ssl_account, @other_user_on_account)
#
#       assert_equal 3, @other_user_on_account.get_all_approved_accounts.count
#       assert_equal 3, @disable_user.get_all_approved_accounts.count
#
#       login_as(@sysadmin, update_cookie(self.controller.cookies, @sysadmin))
#       visit account_path
#       click_on 'Users'
#       first('td', text: @disable_user.email).click # expand user's row
#       find('#user_status_disabled').set(true)      # check disable radio btn
#       click_on 'Logout'
#       delete_all_cookies
#     end
#
#     it 'CANNOT access the disabled users account' do
#       assert_equal 2, @other_user_on_account.get_all_approved_accounts.count
#       assert_equal 0, @disable_user.get_all_approved_accounts.count
#
#       login_as(@other_user_on_account, update_cookie(self.controller.cookies, @other_user_on_account))
#       visit account_path
#       page.must_have_content "ssl account information for #{@other_user_on_account.login}"
#       page.must_have_content "account number: #{@other_user_on_account.ssl_account.acct_number}"
#
#       visit switch_default_ssl_account_user_path(
#         @other_user_on_account, ssl_account_id: @disable_user_ssl.id
#       )
#       # cannot switch to @disable_user's ssl account
#       page.must_have_content "ssl account information for #{@other_user_on_account.login}"
#       page.must_have_content "account number: #{@other_user_on_account.ssl_account.acct_number}"
#     end
#     it 'CAN access other accounts' do
#       login_as(@other_user_on_account, update_cookie(self.controller.cookies, @other_user_on_account))
#
#       # can view own account
#       visit account_path
#       page.must_have_content "ssl account information for #{@other_user_on_account.login}"
#       page.must_have_content "account number: #{@other_user_on_account.ssl_account.acct_number}"
#
#       # can view/switch to @owner's invited ssl account
#       visit switch_default_ssl_account_user_path(
#         @other_user_on_account, ssl_account_id: @owner.ssl_account.id
#       )
#       visit account_path
#       page.must_have_content "ssl account information for #{@other_user_on_account.login}"
#       page.must_have_content "account number: #{@owner.ssl_account.acct_number}"
#       assert_equal           @owner.ssl_account.id, User.find_by(login: 'account_admin_2').default_ssl_account
#     end
#   end
# end
