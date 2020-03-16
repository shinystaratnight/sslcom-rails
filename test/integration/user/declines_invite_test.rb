# require 'rails_helper'
# #
# # Existing user declines invite to an ssl account.
# #
# describe 'Decline ssl account invite' do
#   before do
#     initialize_roles
#     @existing_user_email = 'exist_user@domain.com'
#     @current_owner       = create(:user, :owner)
#     @existing_user       = create(:user, :owner, email: @existing_user_email)
#     @invited_ssl_acct    = @current_owner.ssl_account
#     @existing_user_ssl   = @existing_user.ssl_account
#
#     @existing_user.activate!(
#       user: {login: 'existing_user', password: @password, password_confirmation: @password}
#     )
#
#     login_as(@current_owner, self.controller.cookies)
#     visit account_path
#     click_on 'Users'
#     click_on 'Invite User'
#     fill_in  'user_email', with: @existing_user_email
#     find('input[value="Invite"]').click
#
#     click_on 'Logout'
#     login_as(@existing_user, update_cookie(self.controller.cookies, @existing_user))
#     visit account_path
#   end
#
#   describe 'BEFORE Decline' do
#     it 'can only see their own account' do
#       ssl = @existing_user.ssl_account_users.find_by(ssl_account_id: @invited_ssl_acct.id)
#       page.must_have_content 'Teams(1)'
#       assert_equal 2, @existing_user.ssl_accounts.count
#       assert_equal 2, @existing_user.roles.count
#       # only invited user's own account is approved
#       assert_equal 1, @existing_user.get_all_approved_accounts.count
#       # invited account has expiring approval token
#       refute_nil   ssl.approval_token
#       refute_nil   ssl.token_expires
#       refute       ssl.approved
#     end
#     it 'can see flash notice to accept or reject invitation' do
#       page.must_have_content "You have been invited to join account ##{@invited_ssl_acct.acct_number}.
#         Please click here to accept the invitation. Click decline to reject."
#     end
#   end
#
#   describe 'AFTER Decline' do
#     before do
#       # has one invite to ssl account
#       assert_equal 1, @existing_user.get_pending_accounts.count
#       assert          @existing_user.pending_account_invites?
#
#       find('a', text: 'decline').click
#       sleep 2
#     end
#
#     it 'declined invitation is logged to SystemAudit log' do
#       audit = SystemAudit.last
#
#       refute_nil   audit
#       assert_equal 2, SystemAudit.count # 1 for invite & 1 for decline
#       assert_equal @existing_user.id, audit.owner_id
#       assert_equal @invited_ssl_acct.id, audit.target_id
#       assert_match 'User', audit.owner_type
#       assert_match 'SslAccount', audit.target_type
#       assert_match "User #{@existing_user.login} has declined invitation to team #{@invited_ssl_acct.get_team_name} (##{@invited_ssl_acct.acct_number}).", audit.notes
#       assert_match 'Declined invitation to team (UsersController#decline_account_invite).', audit.action
#     end
#
#     it 'account invite should be declined' do
#       params = {ssl_account_id: @invited_ssl_acct.id}
#       ssl    = @existing_user.ssl_account_users.find_by(params)
#
#       page.must_have_content 'Teams(1)'
#       assert       @existing_user.user_declined_invite?(params)
#       assert_equal @existing_user_ssl.id, @existing_user.default_ssl_account
#       assert_nil   ssl.approval_token
#       assert_nil   ssl.token_expires
#       refute_nil   ssl.declined_at # timestamp exists
#       refute       ssl.approved
#     end
#     it 'has 1 approved account | 0 pending invites' do
#       @existing_user = User.find_by(email: @existing_user_email)
#
#       assert_equal 1, @existing_user.get_all_approved_accounts.count
#       assert_equal 0, @existing_user.get_pending_accounts.count
#       refute          @existing_user.pending_account_invites?
#     end
#     it 'owner should see decline status' do
#       click_on 'Logout'
#       login_as(@current_owner, self.controller.cookies)
#       visit account_path
#       click_on 'Users'
#
#       page.must_have_content 'declined'
#
#       first('td', text: @existing_user_email).click # expand user's row
#       page.must_have_content "declined: #{@existing_user.ssl_account_users.find_by(ssl_account_id: @invited_ssl_acct.id).declined_at.strftime('%b %d, %Y %l:%m %p')}"
#     end
#     it 'sysadmin should see decline status' do
#       sysadmin = create(:user, :sysadmin)
#       click_on 'Logout'
#       login_as(sysadmin, update_cookie(self.controller.cookies, sysadmin))
#       visit account_path
#       click_on 'Users'
#       first('td', text: @existing_user_email).click # expand user's row
#
#       page.must_have_content("#{@invited_ssl_acct.acct_number} [ declined ]")
#     end
#
#   end
# end
