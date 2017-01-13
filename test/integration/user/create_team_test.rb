require 'test_helper'

describe 'user creates a new team' do
  before do
    initialize_roles
    @current_admin = create(:user, :account_admin)
    @ssl_acct      = @current_admin.ssl_account
    login_as(@current_admin, self.controller.cookies)
    visit account_path
    click_on "Teams(#{@current_admin.get_all_approved_accounts.count})"
    click_on '+ Create Team'
    fill_in 'team_name', with: 'team_2'

    assert_equal 1, @current_admin.total_teams_owned.count
    assert_equal 1, SslAccount.count
  end
  
  it 'creates team w/out ssl_slug' do
    first('#ssl_account_create_team').click
  end

  it 'creates team with ssl_slug' do

  end

  it 'max teams reached' do
  end
end
