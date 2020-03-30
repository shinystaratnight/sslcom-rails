# require 'rails_helper'
# #
# # Existing SSL.com user leaves a team.
# # Team that they do not own and have accepted invitation for at one point.
# #
# describe 'Leave team' do
#   before do
#     initialize_roles
#     @owner_user   = create(:user, :owner)
#     @owner_ssl    = @owner_user.ssl_account
#     @billing_user = create_and_approve_user(@owner_ssl, 'billing_login', @billing_role)
#     @billing_ssl  = @billing_user.ssl_account
#     @billing_row  = "[:billing] $0.00 [orders (0)] [transactions (0)] #{Date.today.strftime('%b')}"
#     @b_owner_row  = "[:owner] $0.00 [orders (0)] [transactions (0)] [validations (0)] [users (1)] #{Date.today.strftime('%b')}"
#
#     2.times{login_as(@billing_user, self.controller.cookies)}
#     visit teams_user_path(@billing_user)
#   end
#
#   describe 'BEFORE leaving team' do
#
#     it 'SHOULD see/belong to 2 teams' do
#       page.must_have_content 'Teams(2)'
#       assert_equal 2, @billing_user.ssl_accounts.count
#       assert_equal 2, @billing_user.roles.count
#       assert_equal 2, @billing_user.assignments.count
#       assert_equal 2, @billing_user.get_all_approved_accounts.count
#       assert_equal 2, @owner_user.ssl_account.cached_users.count
#       assert       @billing_user.roles.map(&:name).include? 'owner'
#       assert       @billing_user.roles.map(&:name).include? 'billing'
#
#       page.must_have_content @b_owner_row, count: 1
#       page.must_have_content @billing_row, count: 1
#       page.must_have_content 'leave team', count: 1
#       page.must_have_content @owner_ssl.acct_number, count: 2
#       page.must_have_content @billing_ssl.acct_number, count: 2
#     end
#
#     it 'owner should see 2 users' do
#       click_on 'Logout'
#       login_as(@owner_user, self.controller.cookies)
#       visit account_path
#       click_on 'Users'
#
#       page.must_have_content @billing_user.login, count: 1
#       page.must_have_content @billing_user.email, count: 1
#       page.must_have_content @owner_user.login, count: 1
#       page.must_have_content @owner_user.email, count: 1
#       page.must_have_content "billing", count: 2
#       page.must_have_content 'owner', count: 1
#     end
#   end
#
#   describe 'AFTER leaving team' do
#     before do
#       click_on 'leave team'
#       page.driver.browser.switch_to.alert.accept # accept prompt
#       sleep 1 # allow email notification generation.
#     end
#
#     it '2 email notifications are sent to each user' do
#       # billing user receives leave_team email
#       assert_equal    2, email_total_deliveries
#       assert_match    "You have left SSL.com team #{@owner_ssl.get_team_name}", email_subject(:first)
#       assert_match    @billing_user.email, email_to(:first)
#       assert_match    'noreply@ssl.com', email_from
#       assert_includes email_body(:first), 'You have left SSL.com team.'
#       assert_includes email_body(:first), "If you have done this in error, please feel free to contact #{@owner_user.email} for further instructions."
#       assert_includes email_body(:first), "Team:\t#{@owner_ssl.get_team_name}"
#       assert_includes email_body(:first), "Date:\t#{Date.today.strftime('%b')}"
#
#       # owner user receives leave_team_notify_admins email
#       assert_equal    2, email_total_deliveries
#       assert_match    "User #{@billing_user.login} has left your SSL.com team #{@owner_ssl.get_team_name}", email_subject
#       assert_match    @owner_user.email, email_to
#       assert_match    'noreply@ssl.com', email_from
#       assert_includes email_body, "#{@billing_user.login} has left one of your SSL.com teams."
#       assert_includes email_body, "Team:\t#{@owner_ssl.get_team_name}"
#       assert_includes email_body, "User:\tlogin: #{@billing_user.login} | email: #{@billing_user.email}"
#       assert_includes email_body, "Date:\t#{Date.today.strftime('%b')}"
#     end
#
#     it 'SHOULD see/belong to 1 team they own' do
#       assert_equal 1, @billing_user.ssl_accounts.count
#       assert_equal 1, @billing_user.roles.count
#       assert_equal 1, @billing_user.assignments.count
#       assert_equal 1, @billing_user.get_all_approved_accounts.count
#       assert_equal 1, @owner_user.ssl_account.cached_users.count
#       assert       @billing_user.roles.map(&:name).include? 'owner'
#       refute       @billing_user.roles.map(&:name).include? 'billing'
#
#       page.must_have_content   'Teams(1)'
#       page.must_have_content   @b_owner_row, count: 1
#       refute page.has_content? 'leave team'
#       refute page.has_content? @owner_ssl.acct_number
#       page.must_have_content   @billing_ssl.acct_number, count: 2
#     end
#
#     it 'owner should NOT see user in users index' do
#       click_on 'Logout'
#       login_as(@owner_user, self.controller.cookies)
#       visit account_path
#       click_on 'Users'
#
#       refute page.has_content? @billing_user.login, count: 1
#       refute page.has_content? @billing_user.email, count: 1
#       refute page.has_content? 'billing', count: 1
#       page.must_have_content @owner_user.login, count: 1
#       page.must_have_content @owner_user.email, count: 1
#       page.must_have_content 'owner', count: 1
#     end
#   end
#
#   describe 'CANNOT leave team they own' do
#     it 'should NOT remove user' do
#       # billing user tries to leave team they own
#       visit leave_team_user_path(@billing_user, ssl_account_id: @billing_ssl.id)
#
#       page.must_have_content 'Teams(2)'
#       assert_equal 2, @billing_user.ssl_accounts.count
#       assert_equal 2, @billing_user.roles.count
#       assert_equal 2, @billing_user.assignments.count
#       assert_equal 2, @billing_user.get_all_approved_accounts.count
#       assert_equal 2, @owner_user.ssl_account.cached_users.count
#       assert       @billing_user.roles.map(&:name).include? 'owner'
#       assert       @billing_user.roles.map(&:name).include? 'billing'
#
#       page.must_have_content @b_owner_row, count: 1
#       page.must_have_content @billing_row, count: 1
#       page.must_have_content 'leave team', count: 1
#       page.must_have_content @owner_ssl.acct_number, count: 2
#       page.must_have_content @billing_ssl.acct_number, count: 2
#     end
#   end
# end
