require 'test_helper'

describe 'user creates a new team' do
  before do
    initialize_roles
    @current_admin = create(:user, :account_admin)
    @ssl_acct      = @current_admin.ssl_account
    @company_name  = 'team_2_name'
    @ssl_slug      = 'team_2_slug'
    login_as(@current_admin, self.controller.cookies)
    visit account_path
    click_on "Teams(#{@current_admin.get_all_approved_accounts.count})"
    click_on '+ Create Team'
    fill_in 'team_name', with: @company_name
    
    assert_equal 1, @current_admin.total_teams_owned.count
    assert_equal 1, @current_admin.ssl_accounts.count
    assert_equal 1, @current_admin.assignments.count
    assert_equal 1, SslAccount.count
  end
  
  it 'creates team w/out ssl_slug' do
    first('#ssl_account_create_team').click

    team_added = @current_admin.ssl_accounts.where.not(id: @ssl_acct).first
    assert_equal 2, @current_admin.total_teams_owned.count
    assert_equal 2, @current_admin.ssl_accounts.count
    assert_equal 2, @current_admin.assignments.count
    assert_equal 2, SslAccount.count
    assert_match @company_name, team_added.company_name
    # Both teams show up in Teams index
    assert       page.has_content? @company_name
    assert       page.has_content? SslAccount.first.acct_number
    assert       page.has_content? SslAccount.second.acct_number
    assert       page.has_content?('set default', count: 2)
  end

  it 'creates team with ssl_slug' do
    fill_in 'team_name',            with: @company_name
    fill_in 'ssl_account_ssl_slug', with: @ssl_slug
    first('#ssl_account_create_team').click

    team_added = @current_admin.ssl_accounts.where.not(id: @ssl_acct).first
    assert_equal 2, @current_admin.total_teams_owned.count
    assert_equal 2, @current_admin.ssl_accounts.count
    assert_equal 2, @current_admin.assignments.count
    assert_equal 2, SslAccount.count
    assert_match @company_name, team_added.company_name
    assert_match @ssl_slug, team_added.ssl_slug
    assert       page.has_content? @company_name
    assert       page.has_content? SslAccount.first.acct_number # Both teams show up in Teams index
    assert       page.has_content? SslAccount.second.acct_number
    assert       page.has_content?('set default', count: 2)
  end

  it 'max teams reached' do
    @current_admin.update(max_teams: 1)               # limit: 1 team
    visit teams_user_path(@current_admin)
    
    assert_equal 1, @current_admin.max_teams
    assert       page.has_content?('Teams (max limit of 1 can be owned)')
    assert       page.has_no_content? '+ Create Team' # user cannot add more teams, button NOT displayed

    visit create_team_user_path(@current_admin)       # Permission denied: limit reached
    assert_match root_path, page.current_path
  end
end
