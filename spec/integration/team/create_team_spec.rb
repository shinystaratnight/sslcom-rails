# require 'rails_helper'
#
# describe 'user creates a new team' do
#   before do
#     @current_owner = create(:user, :owner)
#     @ssl_acct      = @current_owner.ssl_account
#     @company_name  = 'team_2_name'
#     @ssl_slug      = 'team_2_slug'
#     login_as(@current_owner, self.controller.cookies)
#     visit account_path
#     click_on "Teams(#{@current_owner.get_all_approved_accounts.count})"
#     click_on "+ Create Team (#{User::OWNED_MAX_TEAMS - 1} Remaining)"
#     fill_in 'team_name', with: @company_name
#
#     assert_equal 1, @current_owner.total_teams_owned.count
#     assert_equal 1, @current_owner.ssl_accounts.count
#     assert_equal 1, @current_owner.assignments.count
#     assert_equal 1, SslAccount.count
#   end
#
#   it 'creates team w/out ssl_slug' do
#     first('#ssl_account_create_team').click
#
#     team_added = @current_owner.ssl_accounts.where.not(id: @ssl_acct).first
#     assert_equal 2, @current_owner.total_teams_owned.count
#     assert_equal 2, @current_owner.ssl_accounts.count
#     assert_equal 2, @current_owner.assignments.count
#     assert_equal 2, SslAccount.count
#     assert_match @company_name, team_added.company_name
#     # Both teams show up in Teams index
#     assert       page.has_content? @company_name
#     assert       page.has_content? SslAccount.first.acct_number
#     assert       page.has_content? SslAccount.second.acct_number
#     assert       page.has_content?('set default', count: 2)
#     assert       page.has_content?('owner', count: 2)
#   end
#
#   it 'creates team with ssl_slug' do
#     fill_in 'ssl_account_ssl_slug', with: @ssl_slug
#     first('#ssl_account_create_team').click
#     sleep 2
#
#     team_added = @current_owner.ssl_accounts.where.not(id: @ssl_acct).first
#     assert_equal 2, @current_owner.total_teams_owned.count
#     assert_equal 2, @current_owner.ssl_accounts.count
#     assert_equal 2, @current_owner.assignments.count
#     assert_equal 2, SslAccount.count
#     assert_match @company_name, team_added.company_name
#     assert_match @ssl_slug, team_added.ssl_slug
#     assert       page.has_content? @company_name
#     assert       page.has_content? SslAccount.first.acct_number # Both teams show up in Teams index
#     assert       page.has_content? SslAccount.second.acct_number
#     assert       page.has_content?('set default', count: 2)
#   end
#
#   it 'max teams reached' do
#     @current_owner.update(max_teams: 1)               # limit: 1 team
#     visit teams_user_path(@current_owner)
#
#     assert_equal 1, @current_owner.max_teams
#     assert       page.has_content?('Teams')
#     assert       page.has_content?('owner', count: 1)
#     assert       page.has_no_content? '+ Create Team' # user cannot add more teams, button NOT displayed
#
#     visit create_team_user_path(@current_owner)       # Permission denied: limit reached
#     assert_match root_path, page.current_path
#   end
#
#   it 'set default team' do
#     default_ssl_id    = @current_owner.ssl_accounts.first.id
#     default_team_path = set_default_team_user_path(@current_owner, ssl_account_id: default_ssl_id)
#
#     first('#ssl_account_create_team').click
#     find("a[href='#{default_team_path}']").click
#
#     assert page.has_no_content?'leave team'
#     assert page.has_content?"+ Create Team (#{User::OWNED_MAX_TEAMS - 2} Remaining)"
#     assert page.has_content?('owner', count: 2)
#     assert page.has_content?('set default', count: 1)  # 1 of 2 teams is already set to default
#     assert_equal default_ssl_id, User.first.main_ssl_account
#   end
# end
